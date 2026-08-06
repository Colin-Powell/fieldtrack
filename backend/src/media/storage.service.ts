import fs from 'fs';
import path from 'path';
import os from 'os';
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
    
    await bucket.upload(localPath, {
      destination,
      metadata: {
        contentType,
        cacheControl: 'public, max-age=31536000',
      }
    });

    const file = bucket.file(destination);
    
    // Generate a long-lived signed URL to bypass Firebase Security Rules
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: '01-01-2100'
    });
    
    return url;
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
    const date = new Date();
    
    // Determine category based on explicitly passed evidenceType
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
      else if (file.mimetype.startsWith('audio/')) category = 'videos'; // Voice notes
    }

    const relDir = this.getRelativeStoragePath(date, category);
    
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    const firebasePath = path.posix.join(relDir, filename);
    
    let storagePath: string = '';
    let thumbnailPath: string | undefined = undefined;

    let width: number | undefined;
    let height: number | undefined;
    let duration: number | undefined;

    const tmpDir = os.tmpdir();
    const absTmpFilePath = path.join(tmpDir, filename);

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
        fs.copyFileSync(file.path, absTmpFilePath);
        
        const meta = await this.getVideoMetadata(absTmpFilePath);
        duration = meta.duration;
        width = meta.width;
        height = meta.height;

        storagePath = await this.uploadToFirebase(absTmpFilePath, firebasePath, file.mimetype);

        const thumbName = `thumb_${uuidv4()}.jpg`;
        const absThumbTmpFilePath = path.join(tmpDir, thumbName);
        
        await this.generateVideoThumbnail(absTmpFilePath, tmpDir, thumbName);
        const firebaseThumbPath = path.posix.join(relDir, thumbName);
        thumbnailPath = await this.uploadToFirebase(absThumbTmpFilePath, firebaseThumbPath, 'image/jpeg');
        
        if (fs.existsSync(absThumbTmpFilePath)) fs.unlinkSync(absThumbTmpFilePath);

      } else {
        fs.copyFileSync(file.path, absTmpFilePath);
        storagePath = await this.uploadToFirebase(absTmpFilePath, firebasePath, file.mimetype);
      }

      // Save Evidence to Database
      const evidence = await prisma.evidence.create({
        data: {
          activityId,
          uploadedById: uploaderId,
          originalName: file.originalname,
          storedName: filename,
          fileExtension: ext,
          mimeType: category === 'images' ? 'image/jpeg' : file.mimetype,
          fileSize: fs.statSync(absTmpFilePath).size,
          width,
          height,
          duration,
          storagePath, // Contains public Firebase URL
          thumbnailPath, // Contains public Firebase URL
          uploadStatus: 'SUCCESS',
          gpsLatitude,
          gpsLongitude,
          gpsAccuracy,
          capturedAt,
        }
      });

      return evidence;

    } catch (error) {
      console.error('Error processing upload:', error);
      throw new Error('Failed to process and store media file');
    } finally {
      if (fs.existsSync(file.path)) fs.unlinkSync(file.path);
      if (fs.existsSync(absTmpFilePath)) fs.unlinkSync(absTmpFilePath);
    }
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
