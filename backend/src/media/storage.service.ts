import fs from 'fs';
import path from 'path';
import os from 'os';
import crypto from 'crypto';
import sharp from 'sharp';
import ffmpeg from 'fluent-ffmpeg';
import ffmpegInstaller from '@ffmpeg-installer/ffmpeg';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../db.js';
import dotenv from 'dotenv';
import { getStorageBucket } from '../firebase_admin.js';

dotenv.config();

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

export class StorageService {
  constructor() {}

  private getRelativeStoragePath(date: Date, type: 'images' | 'videos' | 'documents') {
    const year = date.getFullYear().toString();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return path.posix.join(type, year, month);
  }

  private async uploadToFirebase(localPath: string, destination: string, contentType: string): Promise<string> {
    const bucket = getStorageBucket();
    if (!bucket) {
      throw new Error('Firebase Storage Bucket is not configured.');
    }
    
    const token = crypto.randomUUID();

    await bucket.upload(localPath, {
      destination,
      metadata: {
        contentType,
        cacheControl: 'public, max-age=31536000',
        metadata: {
          firebaseStorageDownloadTokens: token,
        },
      }
    });

    return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(destination)}?alt=media&token=${token}`;
  }

  public async processUpload(
    file: Express.Multer.File, 
    activityId: string, 
    uploaderId: string, 
    gpsLatitude?: number, 
    gpsLongitude?: number, 
    gpsAccuracy?: number,
    capturedAt?: Date,
    evidenceType?: string
  ) {
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;

    let category: 'images' | 'videos' | 'documents' = 'documents';
    
    if (evidenceType === 'photo') {
      category = 'images';
      file.mimetype = 'image/jpeg';
    } else if (evidenceType === 'video') {
      category = 'videos';
      file.mimetype = 'video/mp4';
    } else if (evidenceType === 'voice') {
      category = 'documents'; // Use documents category to bypass ffmpeg video processing
      file.mimetype = 'audio/mp4';
    } else {
      // Fallback
      if (file.mimetype.startsWith('image/')) category = 'images';
      else if (file.mimetype.startsWith('video/')) category = 'videos';
      else if (file.mimetype.startsWith('audio/')) category = 'documents'; // Voice notes/Audio
    }

    // Create the PENDING record
    const evidence = await prisma.evidence.create({
      data: {
        activityId,
        uploadedById: uploaderId,
        originalName: file.originalname,
        storedName: filename,
        fileExtension: ext,
        mimeType: category === 'images' ? 'image/jpeg' : file.mimetype,
        fileSize: file.size,
        storagePath: '', // Will be updated later
        uploadStatus: 'PENDING',
        gpsLatitude,
        gpsLongitude,
        gpsAccuracy,
        capturedAt,
      }
    });

    // Enqueue the background job
    const { mediaQueue } = await import('../utils/queue.js');
    await mediaQueue.add('processUpload', {
      evidenceId: evidence.id,
      file,
      category,
      filename
    });

    return evidence;
  }

  /**
   * Creates a PENDING evidence DB record without doing any processing.
   * The route calls this first, then separately enqueues the job.
   */
  public async createPendingEvidence(
    file: Express.Multer.File,
    activityId: string,
    uploaderId: string,
    gpsLatitude?: number,
    gpsLongitude?: number,
    gpsAccuracy?: number,
    capturedAt?: Date,
    evidenceType?: string
  ) {
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;

    let category: 'images' | 'videos' | 'documents' = 'documents';
    if (evidenceType === 'photo') category = 'images';
    else if (evidenceType === 'video') category = 'videos';
    else if (file.mimetype.startsWith('image/')) category = 'images';
    else if (file.mimetype.startsWith('video/')) category = 'videos';

    return prisma.evidence.create({
      data: {
        activityId,
        uploadedById: uploaderId,
        originalName: file.originalname,
        storedName: filename,
        fileExtension: ext,
        mimeType: file.mimetype,
        fileSize: file.size,
        storagePath: '',
        uploadStatus: 'PENDING',
        gpsLatitude,
        gpsLongitude,
        gpsAccuracy,
        capturedAt,
      }
    });
  }

  // Called by BullMQ worker
  public async processMediaUploadJob(jobData: any) {
    const evidenceId = jobData.evidenceId;
    const evidence = await prisma.evidence.findUnique({
      where: { id: evidenceId },
      select: { storedName: true, originalName: true, mimeType: true, fileSize: true },
    });
    const firebaseTempPath = jobData.firebaseTempPath;
    let filePath = jobData.filePath ?? jobData.file?.path;
    const filename = jobData.filename ?? evidence?.storedName;
    const mimetype = jobData.mimetype ?? evidence?.mimeType ?? 'application/octet-stream';
    const originalname = jobData.originalname ?? evidence?.originalName ?? filename;
    const size = jobData.size ?? evidence?.fileSize ?? 0;
    const category = jobData.category ?? (
      mimetype.startsWith('video/')
        ? 'videos'
        : mimetype.startsWith('image/')
          ? 'images'
          : 'documents'
    );

    if (!firebaseTempPath && !filePath) {
      throw new Error(`Media job ${jobData.evidenceId} has no source file`);
    }

    if (!filename) {
      throw new Error(`Media job ${jobData.evidenceId} has no filename`);
    }

    let downloadDest: string | undefined;

    if (firebaseTempPath) {
      downloadDest = path.join(os.tmpdir(), `dl_${uuidv4()}_${originalname}`);
      const bucket = getStorageBucket();
      if (!bucket) throw new Error('Firebase Storage Bucket is not configured.');
      await bucket.file(firebaseTempPath).download({ destination: downloadDest });
      filePath = downloadDest;
    }

    const file = {
      path: filePath,
      mimetype,
      originalname,
      size,
    } as Express.Multer.File;
    const date = new Date();
    
    const relDir = this.getRelativeStoragePath(date, category);
    const firebasePath = path.posix.join(relDir, filename);

    let storagePath: string = '';
    let thumbnailPath: string | undefined = undefined;

    let width: number | undefined;
    let height: number | undefined;
    let duration: number | undefined;

    const tmpDir = os.tmpdir();
    const absTmpFilePath = path.join(tmpDir, filename);
    let compressedPath: string | undefined;
    let completed = false;

    try {
      if (category === 'images') {
        const imageInfo = await sharp(file.path)
          .resize({ width: 1920, height: 1920, fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toFile(absTmpFilePath);
          
        width = imageInfo.width;
        height = imageInfo.height;

        storagePath = await this.uploadToFirebase(absTmpFilePath, firebasePath, 'image/jpeg');

        const thumbName = `thumb_${filename}`;
        const absThumbTmpFilePath = path.join(tmpDir, thumbName);
        
        await sharp(file.path)
          .resize({ width: 256, height: 256, fit: 'cover' })
          .jpeg({ quality: 60 })
          .toFile(absThumbTmpFilePath);
        
        const firebaseThumbPath = path.posix.join(relDir, thumbName);
        thumbnailPath = await this.uploadToFirebase(absThumbTmpFilePath, firebaseThumbPath, 'image/jpeg');
        
        if (fs.existsSync(absThumbTmpFilePath)) fs.unlinkSync(absThumbTmpFilePath);

      } else if (category === 'videos') {
        const compressedFilename = `${path.basename(filename, path.extname(filename))}.mp4`;
        compressedPath = path.join(tmpDir, compressedFilename);

        await this.compressVideo(file.path, compressedPath);
        
        const meta = await this.getVideoMetadata(compressedPath);
        duration = meta.duration;
        width = meta.width;
        height = meta.height;

        storagePath = await this.uploadToFirebase(
          compressedPath,
          path.posix.join(relDir, compressedFilename),
          'video/mp4',
        );

        const thumbName = `thumb_${uuidv4()}.jpg`;
        const absThumbTmpFilePath = path.join(tmpDir, thumbName);
        
        await this.generateVideoThumbnail(compressedPath, tmpDir, thumbName);
        const firebaseThumbPath = path.posix.join(relDir, thumbName);
        thumbnailPath = await this.uploadToFirebase(absThumbTmpFilePath, firebaseThumbPath, 'image/jpeg');
        
        if (fs.existsSync(absThumbTmpFilePath)) fs.unlinkSync(absThumbTmpFilePath);
      } else {
        fs.copyFileSync(file.path, absTmpFilePath);
        storagePath = await this.uploadToFirebase(absTmpFilePath, firebasePath, file.mimetype);
      }

      await prisma.evidence.update({
        where: { id: evidenceId },
        data: {
          width,
          height,
          duration,
          storagePath,
          thumbnailPath,
          uploadStatus: 'SUCCESS',
        }
      });
      completed = true;

    } catch (error) {
      console.error('Error processing upload:', error);
      await prisma.evidence.update({
        where: { id: evidenceId },
        data: { uploadStatus: 'FAILED' }
      });
      throw new Error('Failed to process and store media file');
    } finally {
      if (completed && filePath && fs.existsSync(filePath)) fs.unlinkSync(filePath);
      if (fs.existsSync(absTmpFilePath)) fs.unlinkSync(absTmpFilePath);
      if (compressedPath && fs.existsSync(compressedPath)) fs.unlinkSync(compressedPath);
      if (downloadDest && fs.existsSync(downloadDest)) fs.unlinkSync(downloadDest);
      if (firebaseTempPath) {
        const bucket = getStorageBucket();
        if (bucket) {
          bucket.file(firebaseTempPath).delete().catch(err => console.error('Failed to delete firebaseTempPath', err));
        }
      }
    }
  }

  private compressVideo(inputPath: string, outputPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .videoCodec('libx264')
        .audioCodec('aac')
        .outputOptions([
          '-preset veryfast',
          '-crf 28',
          '-maxrate 2500k',
          '-bufsize 5000k',
          '-movflags +faststart',
          '-vf scale=w=1280:h=1280:force_original_aspect_ratio=decrease',
        ])
        .on('end', () => resolve())
        .on('error', reject)
        .save(outputPath);
    });
  }

  private getVideoMetadata(filePath: string): Promise<{ duration?: number, width?: number, height?: number }> {
    return new Promise((resolve, reject) => {
      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err) return reject(err);
        const stream = metadata.streams.find(s => s.codec_type === 'video');
        resolve({
          duration: metadata.format.duration ? Math.round(metadata.format.duration) : undefined,
          width: stream?.width,
          height: stream?.height,
        });
      });
    });
  }

  private generateVideoThumbnail(videoPath: string, folder: string, filename: string): Promise<void> {
    return new Promise((resolve, reject) => {
      ffmpeg(videoPath)
        .on('end', () => resolve())
        .on('error', (err) => reject(err))
        .screenshots({
          count: 1,
          folder: folder,
          filename: filename,
          size: '256x256'
        });
    });
  }
}

export const processMediaUpload = async (jobData: any) => {
  const service = new StorageService();
  return await service.processMediaUploadJob(jobData);
};
