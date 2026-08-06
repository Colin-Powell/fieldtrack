import { Router, Request, Response } from 'express';
import multer from 'multer';
import { StorageService } from './storage.service.js';
import { uploadsLogger } from '../utils/logger.js';
import { authenticate } from '../auth/auth.middleware.js';
import { prisma } from '../db.js';

const router = Router();
const storageService = new StorageService();

// Set up multer for temporary file storage with MIME type checking
const ALLOWED_MIME_TYPES = [
  'image/jpeg', 'image/png', 'image/webp',
  'video/mp4', 'video/webm',
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

    const { activityId, gpsLatitude, gpsLongitude, gpsAccuracy, capturedAt } = req.body;

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

    const evidence = await storageService.processUpload(
      file,
      activity.id,
      userId,
      gpsLatitude ? parseFloat(gpsLatitude) : undefined,
      gpsLongitude ? parseFloat(gpsLongitude) : undefined,
      gpsAccuracy ? parseFloat(gpsAccuracy) : undefined,
      capturedAt ? new Date(capturedAt) : undefined
    );

    res.status(201).json(evidence);
  } catch (error) {
    uploadsLogger.error('Upload media failed:', { error, activityId: req.body?.activityId });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

export default router;
