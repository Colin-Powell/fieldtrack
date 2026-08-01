import { Router, Request, Response } from 'express';
import multer from 'multer';
import { StorageService } from './storage.service.js';
import { uploadsLogger } from '../utils/logger.js';

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

router.post('/upload', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const { activityId, uploaderId, gpsLatitude, gpsLongitude, gpsAccuracy, capturedAt } = req.body;

    if (!activityId || !uploaderId) {
      return res.status(400).json({ error: 'Missing activityId or uploaderId' });
    }

    const evidence = await storageService.processUpload(
      file,
      activityId,
      uploaderId,
      gpsLatitude ? parseFloat(gpsLatitude) : undefined,
      gpsLongitude ? parseFloat(gpsLongitude) : undefined,
      gpsAccuracy ? parseFloat(gpsAccuracy) : undefined,
      capturedAt ? new Date(capturedAt) : undefined
    );

    res.status(201).json(evidence);
  } catch (error) {
    uploadsLogger.error('Upload media failed:', { error, body: req.body });
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

export default router;
