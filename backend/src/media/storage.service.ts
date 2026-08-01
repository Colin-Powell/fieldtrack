import fs from 'fs';
import path from 'path';
import sharp from 'sharp';
import ffmpeg from 'fluent-ffmpeg';
import ffmpegInstaller from '@ffmpeg-installer/ffmpeg';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../db.js';
import dotenv from 'dotenv';

dotenv.config();

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

export const BASE_STORAGE_DIR = process.env.STORAGE_DIR 
  ? path.resolve(process.env.STORAGE_DIR) 
  : path.join(process.cwd(), 'storage');

export class StorageService {
  constructor() {
    this.ensureDirectory(BASE_STORAGE_DIR);
  }

  private ensureDirectory(dirPath: string) {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  }

  private getRelativeStoragePath(date: Date, type: 'images' | 'videos' | 'documents') {
    const year = date.getFullYear().toString();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return path.join(type, year, month);
  }

  public async processUpload(
    file: Express.Multer.File, 
    activityId: string, 
    uploaderId: string, 
    gpsLatitude?: number, 
    gpsLongitude?: number, 
    gpsAccuracy?: number,
    capturedAt?: Date
  ) {
    const date = new Date();
    
    // Determine category
    let category: 'images' | 'videos' | 'documents' = 'documents';
    if (file.mimetype.startsWith('image/')) category = 'images';
    else if (file.mimetype.startsWith('video/')) category = 'videos';

    const relDir = this.getRelativeStoragePath(date, category);
    const absDir = path.join(BASE_STORAGE_DIR, relDir);
    this.ensureDirectory(absDir);

    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    const absFilePath = path.join(absDir, filename);
    const relativeStoragePath = path.join(relDir, filename).replace(/\\/g, '/');
    let thumbnailPath: string | undefined;

    let width: number | undefined;
    let height: number | undefined;
    let duration: number | undefined;

    try {
      // 1. Write the base file
      if (category === 'images') {
        // Compress and resize image using Sharp
        const imageInfo = await sharp(file.path)
          .resize({ width: 1920, height: 1920, fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toFile(absFilePath);
          
        width = imageInfo.width;
        height = imageInfo.height;

        // Generate thumbnail
        const thumbName = `thumb_${filename}`;
        await sharp(file.path)
          .resize({ width: 256, height: 256, fit: 'cover' })
          .jpeg({ quality: 60 })
          .toFile(path.join(absDir, thumbName));
        
        thumbnailPath = path.join(relDir, thumbName).replace(/\\/g, '/');
      } else if (category === 'videos') {
        fs.copyFileSync(file.path, absFilePath);
        
        // Extract metadata using FFmpeg
        const meta = await this.getVideoMetadata(absFilePath);
        duration = meta.duration;
        width = meta.width;
        height = meta.height;

        // Generate thumbnail for video
        const thumbName = `thumb_${uuidv4()}.jpg`;
        await this.generateVideoThumbnail(absFilePath, absDir, thumbName);
        thumbnailPath = path.join(relDir, thumbName).replace(/\\/g, '/');
      } else {
        fs.copyFileSync(file.path, absFilePath);
      }

      // 2. Save Evidence to Database
      const evidence = await prisma.evidence.create({
        data: {
          activityId,
          uploadedById: uploaderId,
          originalName: file.originalname,
          storedName: filename,
          fileExtension: ext,
          mimeType: file.mimetype,
          fileSize: fs.statSync(absFilePath).size,
          width,
          height,
          duration,
          storagePath: relativeStoragePath,
          thumbnailPath,
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
      // Clean up multer temp file
      if (fs.existsSync(file.path)) {
        fs.unlinkSync(file.path);
      }
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
