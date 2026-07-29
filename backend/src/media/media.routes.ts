import { Router, Request, Response } from 'express';
import multer from 'multer';
import { StorageService } from './storage.service.js';

const router = Router();
const storageService = new StorageService();

// Set up multer for temporary file storage
const upload = multer({ 
  dest: 'temp_uploads/',
  limits: { fileSize: 100 * 1024 * 1024 } // 100MB limit
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
    console.error('[uploadMedia]', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

export default router;
