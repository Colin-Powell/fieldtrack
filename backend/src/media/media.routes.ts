import { Router, Request, Response } from 'express';
import multer from 'multer';
import { StorageService } from './storage.service.js';
import { uploadsLogger } from '../utils/logger.js';
import { authenticate } from '../auth/auth.middleware.js';
import { prisma } from '../db.js';
import { mediaQueue } from '../utils/queue.js';

const router = Router();
const storageService = new StorageService();

// Set up multer for temporary file storage with MIME type checking
const ALLOWED_MIME_TYPES = [
  'image/jpeg', 'image/png', 'image/webp',
  'video/mp4', 'video/webm',
  'audio/mp4', 'audio/m4a', 'audio/aac', 'audio/mpeg', 'audio/x-m4a', 'application/octet-stream',
  'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
];

const upload = multer({ 
  dest: 'temp_uploads/',
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB absolute max limit
  fileFilter: (req, file, cb) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}`));
    }
  }
});

router.post('/upload', authenticate, upload.single('file'), async (req: Request, res: Response) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { activityId, gpsLatitude, gpsLongitude, gpsAccuracy, capturedAt, evidenceType } = req.body;

    if (!activityId) {
      return res.status(400).json({ error: 'Missing activityId' });
    }

    const activity = await prisma.fieldLog.findUnique({
      where: { id: activityId },
      select: { id: true, studentId: true },
    });

    if (!activity) {
      return res.status(404).json({ error: 'Activity not found' });
    }

    if (req.user?.role === 'STUDENT' && activity.studentId !== userId) {
      return res.status(403).json({ error: 'You can only upload evidence to your own activities' });
    }

    // Create a placeholder evidence record immediately so the client has an ID to track
    const evidence = await storageService.createPendingEvidence(
      file,
      activity.id,
      userId,
      gpsLatitude ? parseFloat(gpsLatitude) : undefined,
      gpsLongitude ? parseFloat(gpsLongitude) : undefined,
      gpsAccuracy ? parseFloat(gpsAccuracy) : undefined,
      capturedAt ? new Date(capturedAt) : undefined,
      evidenceType
    );

    // Enqueue the heavy processing job (FFmpeg, Sharp, Firebase upload) 
    const job = await mediaQueue.add('processUpload', {
      evidenceId: evidence.id,
      filePath: file.path,
      activityId: activity.id,
      userId,
      mimetype: file.mimetype,
      originalname: file.originalname,
      size: file.size,
    }, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 },
      removeOnComplete: true,
      removeOnFail: false,
    });

    // Return 202 Accepted immediately — processing happens in the background
    return res.status(202).json({
      success: true,
      jobId: job.id,
      evidenceId: evidence.id,
      status: 'processing',
      message: 'File uploaded successfully. Media processing has started in the background.',
    });
  } catch (error) {
    uploadsLogger.error('Upload media failed:', { error, activityId: req.body?.activityId });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

export default router;

