# FieldTrack Scaling - Critical Implementation Checklist
## Quick-Fix Action Items for Production Readiness

---

## 🔴 CRITICAL (BLOCK BEFORE 10K USERS)

### 1. Add Database Indexes
**File:** `backend/prisma/schema.prisma`  
**Effort:** 10 min  
**Impact:** 50-100x query performance improvement

**Add these indexes to the schema:**

```prisma
// Model: FieldSession
model FieldSession {
  // ... existing fields ...
  
  @@index([studentId])
  @@index([checkOutTime])
  @@index([status])
  @@index([createdAt])
}

// Model: FieldLog
model FieldLog {
  // ... existing fields ...
  
  @@index([studentId])
  @@index([status])
  @@index([timestamp])
  @@index([studentId, status])  // Composite for filtering
}

// Model: LocationPing
model LocationPing {
  // ... existing fields ...
  
  @@index([sessionId])
  @@index([timestamp])
}

// Model: AuditLog
model AuditLog {
  // ... existing fields ...
  
  @@index([timestamp])
  @@index([actorId])
  @@index([userId])
  @@index([action])
}

// Model: Notification
model Notification {
  // ... existing fields ...
  
  @@index([recipientId])
  @@index([createdAt])
  @@index([isRead])
}

// Model: Evidence
model Evidence {
  // ... existing fields ...
  
  @@index([activityId])
  @@index([uploadedById])
}

// Model: RefreshToken
model RefreshToken {
  // ... existing fields ...
  
  @@index([userId])
  @@index([expiresAt])
}

// Model: StudentProfile
model StudentProfile {
  // ... existing fields ...
  
  @@index([supervisorId])
}

// Model: User
model User {
  // ... existing fields ...
  
  @@index([email])
  @@index([role])
}
```

**Commands to run:**
```bash
cd backend
npx prisma format                    # Format schema
npx prisma db push                   # Apply indexes to database
npx prisma db execute --stdin < prismaMigration.sql  # If complex
```

---

### 2. Activate Cache Middleware on Dashboard
**File:** `backend/src/developer/developer.routes.ts`  
**Effort:** 20 min  
**Impact:** Dashboard queries drop from 2-5s to <200ms

**Add to top of file:**
```typescript
import { cacheMiddleware } from '../utils/cache.js';
```

**Update route (around line 249):**
```typescript
// ❌ BEFORE:
// router.get('/dashboard-aggregate', async (_req: Request, res: Response) => {

// ✅ AFTER:
router.get('/dashboard-aggregate', cacheMiddleware(300), async (_req: Request, res: Response) => {
  // Cache for 5 minutes (300 seconds)
  // ... rest of route ...
});
```

**Also apply to these dashboard routes:**
```typescript
router.get('/logs', cacheMiddleware(60), async (_req, res) => { ... });
router.get('/health', cacheMiddleware(30), async (_req, res) => { ... });
router.get('/export', cacheMiddleware(600), async (_req, res) => { ... });  // 10 min
```

---

### 3. Move Media Upload to Queue (ASYNC)
**File:** `backend/src/media/media.routes.ts`  
**Effort:** 30 min  
**Impact:** Releases event loop, processes 1000+ uploads simultaneously

**Full replacement for upload route:**

```typescript
import { Router, Request, Response } from 'express';
import multer from 'multer';
import { uploadsLogger } from '../utils/logger.js';
import { authenticate } from '../auth/auth.middleware.js';
import { prisma } from '../db.js';
import { mediaQueue } from '../utils/queue.js';  // ← ADD THIS

const router = Router();

// Set up multer for temporary file storage
const ALLOWED_MIME_TYPES = [
  'image/jpeg', 'image/png', 'image/webp',
  'video/mp4', 'video/webm',
  'audio/mp4', 'audio/m4a', 'audio/aac', 'audio/mpeg',
  'application/pdf', 'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
];

const upload = multer({
  dest: 'temp_uploads/',
  limits: { fileSize: 50 * 1024 * 1024 },
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

    // ✅ QUEUE THE JOB INSTEAD OF PROCESSING SYNCHRONOUSLY
    const job = await mediaQueue.add('processUpload', {
      filePath: file.path,
      originalName: file.originalname,
      mimeType: file.mimetype,
      activityId: activity.id,
      uploaderId: userId,
      gpsLatitude: gpsLatitude ? parseFloat(gpsLatitude) : undefined,
      gpsLongitude: gpsLongitude ? parseFloat(gpsLongitude) : undefined,
      gpsAccuracy: gpsAccuracy ? parseFloat(gpsAccuracy) : undefined,
      capturedAt: capturedAt ? new Date(capturedAt) : undefined,
      evidenceType,
      fileSize: file.size,
    }, {
      attempts: 3,  // Retry 3 times on failure
      backoff: {
        type: 'exponential',
        delay: 2000  // Start with 2 second delay
      },
      removeOnComplete: true,
    });

    uploadsLogger.info('Media upload queued', { jobId: job.id, activityId, uploaderId: userId });

    // ✅ RETURN 202 ACCEPTED (processing in background)
    res.status(202).json({
      success: true,
      jobId: job.id,
      message: 'File is being processed',
      status: 'processing'
    });

  } catch (error) {
    uploadsLogger.error('Upload failed', { error, activityId: req.body?.activityId });
    res.status(500).json({ error: 'Upload failed' });
  }
});

// ✅ NEW: Allow clients to check upload progress
router.get('/status/:jobId', authenticate, async (req: Request, res: Response) => {
  try {
    const job = await mediaQueue.getJob(req.params.jobId);
    
    if (!job) {
      return res.status(404).json({ error: 'Job not found' });
    }

    const state = await job.getState();
    const progress = job.progress();
    const data = job.data;

    res.json({
      jobId: job.id,
      state,  // 'waiting', 'active', 'completed', 'failed'
      progress,
      isCompleted: await job.isCompleted(),
      isFailed: await job.isFailed(),
      result: state === 'completed' ? job.returnvalue : null,
      failedReason: state === 'failed' ? job.failedReason : null,
    });
  } catch (error) {
    uploadsLogger.error('Failed to get job status', { error, jobId: req.params.jobId });
    res.status(500).json({ error: 'Failed to get status' });
  }
});

export default router;
```

---

### 4. Create Media Processing Service
**File:** `backend/src/media/media.service.ts` (NEW FILE)  
**Effort:** 40 min

**Create this file:**

```typescript
import { execFile } from 'child_process';
import ffmpegInstaller from '@ffmpeg-installer/ffmpeg';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../db.js';
import { uploadsLogger } from '../utils/logger.js';
import { getStorageBucket } from '../firebase_admin.js';

const ffmpegPath = ffmpegInstaller.path;

export async function processMediaUpload(jobData: any) {
  const {
    filePath,
    originalName,
    mimeType,
    activityId,
    uploaderId,
    gpsLatitude,
    gpsLongitude,
    gpsAccuracy,
    capturedAt,
    evidenceType,
    fileSize,
  } = jobData;

  let storedFilePath: string | null = null;
  let thumbnailPath: string | null = null;

  try {
    uploadsLogger.info('Processing media upload', { activityId, uploaderId });

    // Determine media type
    let category: 'images' | 'videos' | 'documents' = 'documents';
    if (evidenceType === 'photo' || mimeType.startsWith('image/')) {
      category = 'images';
    } else if (evidenceType === 'video' || mimeType.startsWith('video/')) {
      category = 'videos';
    }

    const year = new Date().getFullYear().toString();
    const month = (new Date().getMonth() + 1).toString().padStart(2, '0');
    const storageDir = path.join(process.cwd(), 'storage', category, year, month);

    // Create directory if it doesn't exist
    await fs.mkdir(storageDir, { recursive: true });

    const ext = path.extname(originalName);
    const newFilename = `${uuidv4()}${ext}`;
    const newFilePath = path.join(storageDir, newFilename);

    // Process based on file type
    if (category === 'images') {
      // Re-encode image to strip EXIF
      await sharp(filePath)
        .withMetadata(false)  // Remove metadata/EXIF
        .toFile(newFilePath);
      
      storedFilePath = path.relative(path.join(process.cwd(), 'storage'), newFilePath);
    } else if (category === 'videos') {
      // For videos, just move the file (FFmpeg processing optional)
      await fs.copyFile(filePath, newFilePath);
      storedFilePath = path.relative(path.join(process.cwd(), 'storage'), newFilePath);

      // Generate thumbnail asynchronously (non-blocking)
      try {
        const thumbnailName = `${uuidv4()}.jpg`;
        const thumbnailFullPath = path.join(storageDir, thumbnailName);
        
        await new Promise((resolve, reject) => {
          execFile(ffmpegPath, [
            '-i', filePath,
            '-ss', '00:00:01',
            '-vf', 'scale=320:-1',
            '-y',
            thumbnailFullPath
          ], (error) => {
            if (error) reject(error);
            else resolve(null);
          });
        });
        
        thumbnailPath = path.relative(path.join(process.cwd(), 'storage'), thumbnailFullPath);
      } catch (thumbError) {
        uploadsLogger.warn('Failed to generate thumbnail', { error: thumbError, activityId });
        // Continue without thumbnail
      }
    } else {
      // Documents/other files: just move
      await fs.copyFile(filePath, newFilePath);
      storedFilePath = path.relative(path.join(process.cwd(), 'storage'), newFilePath);
    }

    // Save to Firebase (if configured)
    let fileUrl: string | undefined;
    try {
      const bucket = getStorageBucket();
      if (bucket) {
        const destination = path.join(category, year, month, newFilename).replace(/\\/g, '/');
        await bucket.upload(newFilePath, {
          destination,
          metadata: {
            contentType: mimeType,
            cacheControl: 'public, max-age=31536000',
          }
        });

        const file = bucket.file(destination);
        const [url] = await file.getSignedUrl({
          action: 'read',
          expires: '01-01-2100'
        });
        fileUrl = url;
      }
    } catch (firebaseError) {
      uploadsLogger.warn('Failed to upload to Firebase', { error: firebaseError });
      // Fall back to local storage URL
      fileUrl = `/storage/${storedFilePath}`;
    }

    // Create Evidence record in database
    const evidence = await prisma.evidence.create({
      data: {
        activityId,
        uploadedById: uploaderId,
        originalName,
        storedName: newFilename,
        fileExtension: ext.slice(1),
        mimeType,
        fileSize,
        storagePath: storedFilePath || newFilePath,
        fileUrl: fileUrl || `/storage/${storedFilePath}`,
        uploadStatus: 'SUCCESS',
        gpsLatitude,
        gpsLongitude,
        gpsAccuracy,
        capturedAt,
        thumbnailPath,
      }
    });

    // Clean up temporary file
    await fs.unlink(filePath).catch(() => {});

    uploadsLogger.info('Media upload completed', {
      activityId,
      uploaderId,
      evidenceId: evidence.id
    });

    return evidence;

  } catch (error) {
    uploadsLogger.error('Media processing failed', { error, activityId, uploaderId });
    
    // Clean up temporary file
    try {
      await fs.unlink(filePath);
    } catch (cleanupError) {
      uploadsLogger.warn('Failed to clean up temp file', { error: cleanupError });
    }

    throw error;
  }
}
```

**Update queue.ts to use this service:**

```typescript
export const mediaWorker = new Worker('mediaQueue', async job => {
  if (job.name === 'processUpload') {
    const { processMediaUpload } = await import('../media/media.service.js');
    return await processMediaUpload(job.data);  // ← Return result
  }
}, {
  connection,
  concurrency: 5,  // ← Max 5 concurrent uploads (prevents memory spike)
});
```

---

### 5. Complete Pagination Rollout
**Files:** Multiple controller files  
**Effort:** 45 min

**Apply pagination to these controllers:**

#### A. `backend/src/notifications/notification.routes.ts`

```typescript
router.get('/', authenticate, async (req: Request, res: Response) => {
  try {
    const userId = req.user?.userId;
    const limit = parseInt(req.query.limit as string, 10) || 50;
    const offset = parseInt(req.query.offset as string, 10) || 0;

    const notifications = await prisma.notification.findMany({
      where: { recipientId: userId },
      take: limit,
      skip: offset,
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.notification.count({
      where: { recipientId: userId }
    });

    res.json({
      data: notifications,
      pagination: { limit, offset, total }
    });
  } catch (error) {
    // ...error handling...
  }
});
```

#### B. `backend/src/reports/reports.routes.ts`

```typescript
router.get('/', authenticate, async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 50;
  const offset = parseInt(req.query.offset as string) || 0;

  const reports = await prisma.report.findMany({
    take: limit,
    skip: offset,
    orderBy: { createdAt: 'desc' }
  });

  res.json({ reports, pagination: { limit, offset } });
});
```

#### C. `backend/src/reviews/review.routes.ts`

```typescript
router.get('/', authenticate, async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 50;
  const offset = parseInt(req.query.offset as string) || 0;

  const reviews = await prisma.review.findMany({
    take: limit,
    skip: offset,
    orderBy: { createdAt: 'desc' },
    include: { reviewer: { select: { name: true, email: true } } }
  });

  res.json({ reviews, pagination: { limit, offset } });
});
```

---

## 🟡 HIGH PRIORITY (Next 2 Days)

### 6. Configure Job Concurrency & Retry
**File:** `backend/src/utils/queue.ts`  
**Effort:** 15 min

**Update workers with concurrency limits:**

```typescript
import { Queue, Worker, QueueEvents } from 'bullmq';
import { redis } from './redis.js';

const connection = redis;

// Create queues
export const notificationQueue = new Queue('notificationQueue', { connection });
export const csvImportQueue = new Queue('csvImportQueue', { connection });
export const mediaQueue = new Queue('mediaQueue', { connection });
export const auditQueue = new Queue('auditQueue', { connection });

// Initialize Workers with concurrency & error handling
export const notificationWorker = new Worker('notificationQueue', async job => {
  if (job.name === 'bulkNotification') {
    const { processBulkNotifications } = await import('../notifications/notification.service.js');
    return await processBulkNotifications(job.data);
  }
}, {
  connection,
  concurrency: 50,  // High concurrency for lightweight jobs
});

export const csvImportWorker = new Worker('csvImportQueue', async job => {
  if (job.name === 'importUsers') {
    const { processCsvImport } = await import('../admins/admins.csv.js');
    return await processCsvImport(job.data);
  }
}, {
  connection,
  concurrency: 2,  // Low concurrency for CPU-intensive work
});

export const mediaWorker = new Worker('mediaQueue', async job => {
  if (job.name === 'processUpload') {
    const { processMediaUpload } = await import('../media/media.service.js');
    return await processMediaUpload(job.data);
  }
}, {
  connection,
  concurrency: 5,  // Limited to prevent memory exhaustion
  settings: {
    maxStalledCount: 2,  // Max retries when stalled
    lockDuration: 60000,  // 1 minute lock
    lockRenewTime: 15000,  // Renew every 15 seconds
  }
});

export const auditWorker = new Worker('auditQueue', async job => {
  if (job.name === 'logAudit') {
    const { processAuditLog } = await import('../services/audit-log.service.js');
    return await processAuditLog(job.data);
  }
}, {
  connection,
  concurrency: 100,  // Very high concurrency (lightweight DB writes)
});

// Error handling
notificationWorker.on('failed', (job, err) => {
  console.error(`Notification Job ${job?.id} failed:`, err.message);
});

mediaWorker.on('failed', (job, err) => {
  console.error(`Media Job ${job?.id} failed after ${job?.attemptsMade} attempts:`, err.message);
});

auditWorker.on('failed', (job, err) => {
  console.error(`Audit Job ${job?.id} failed:`, err.message);
});

// Optional: Log completed jobs
auditWorker.on('completed', (job) => {
  console.log(`Audit job ${job.id} completed in ${Date.now() - job.timestamp}ms`);
});
```

---

### 7. Create .env.example
**File:** `backend/.env.example` (NEW)  
**Effort:** 10 min

```env
# ═══════════════════════════════════════════════════════
# FieldTrack Backend Environment Configuration
# ═══════════════════════════════════════════════════════

# NODE ENVIRONMENT
NODE_ENV=production
PORT=3000

# ───────────────────────────────────────────────────────
# DATABASE
# ───────────────────────────────────────────────────────
# PostgreSQL connection string
# Format: postgresql://[user]:[password]@[host]:[port]/[database]
DATABASE_URL=postgresql://fieldtrack:password@localhost:5432/fieldtrack

# Database connection pool settings (set in code, but document here)
# MAX_POOL_CONNECTIONS=100
# MIN_POOL_CONNECTIONS=20

# ───────────────────────────────────────────────────────
# REDIS (for caching, rate limiting, job queue)
# ───────────────────────────────────────────────────────
REDIS_URL=redis://localhost:6379
# REDIS_PASSWORD=your_redis_password  # If needed

# ───────────────────────────────────────────────────────
# AUTHENTICATION
# ───────────────────────────────────────────────────────
# JWT signing key (generate with: openssl rand -hex 32)
JWT_SECRET=your-very-long-random-secret-key-32-bytes-minimum

# Admin developer dashboard credentials
ADMIN_EMAIL=admin@university.ac.ke
ADMIN_PASSWORD=InitialStrongPassword123!

# ───────────────────────────────────────────────────────
# CORS
# ───────────────────────────────────────────────────────
# Comma-separated list of allowed origins
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080,https://fieldtrack.top

# ───────────────────────────────────────────────────────
# STORAGE
# ───────────────────────────────────────────────────────
# Local storage directory for media files
STORAGE_DIR=/var/www/fieldtrack/backend/storage

# Firebase Storage (for backup/cloud storage)
FIREBASE_ADMIN_SDK_PATH=/path/to/firebase-service-account-key.json

# ───────────────────────────────────────────────────────
# EMAIL (SMTP for password resets, notifications)
# ───────────────────────────────────────────────────────
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=noreply@fieldtrack.app
SMTP_PASS=your-app-specific-password
SMTP_FROM=FieldTrack Support <noreply@fieldtrack.app>

# ───────────────────────────────────────────────────────
# LOGGING
# ───────────────────────────────────────────────────────
LOG_LEVEL=info
LOG_DIR=/var/www/fieldtrack/backend/logs

# ───────────────────────────────────────────────────────
# THIRD-PARTY INTEGRATIONS
# ───────────────────────────────────────────────────────
# GPS/Geocoding (Nominatim, Google Maps, etc.)
# GEOCODING_API_KEY=...

# Payment gateway (if needed)
# STRIPE_KEY=...
# STRIPE_SECRET=...

# ═══════════════════════════════════════════════════════
# NOTES FOR DEPLOYMENT
# ═══════════════════════════════════════════════════════
# 1. Generate JWT_SECRET: openssl rand -hex 32
# 2. Use strong passwords (min 12 characters, mix of types)
# 3. Use environment variable secrets manager in production
#    (AWS Secrets Manager, HashiCorp Vault, etc.)
# 4. Never commit actual .env file to Git
# 5. Set NODE_ENV=production in production
# 6. Ensure PostgreSQL & Redis are accessible and firewalled
# 7. Configure backups for database and storage
```

**In `backend/.gitignore`, add:**
```
.env
.env.local
.env.*.local
```

---

## 🟢 TESTING & VALIDATION

### Test Media Queue Processing
```bash
# 1. Start Redis locally
redis-server

# 2. In terminal 1: Start backend
npm run dev

# 3. In terminal 2: Test upload
curl -X POST http://localhost:3000/api/v1/media/upload \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@test-image.jpg" \
  -F "activityId=123" \
  -F "evidenceType=photo"

# Response should be 202 Accepted with jobId

# 4. Monitor Redis queue
redis-cli MONITOR
# or use BullBoard web interface

# 5. Check job status
curl http://localhost:3000/api/v1/media/status/JOB_ID
```

### Load Test Index Performance
```bash
# Before indexes
time psql -U fieldtrack fieldtrack -c "
  SELECT * FROM \"FieldLog\" 
  WHERE \"studentId\" = '...' AND status = 'SUBMITTED'
  ORDER BY \"timestamp\" DESC LIMIT 50;"

# After indexes (should be 50-100x faster)
```

---

## 📋 IMPLEMENTATION CHECKLIST

Priority 1 (CRITICAL):
- [ ] Add database indexes
- [ ] Cache dashboard routes
- [ ] Move media upload to queue
- [ ] Create media.service.ts
- [ ] Apply pagination to all list endpoints

Priority 2 (HIGH):
- [ ] Configure job concurrency & retry logic
- [ ] Create .env.example
- [ ] Test media queue at scale (100 concurrent)
- [ ] Monitor queue health

Priority 3 (MEDIUM):
- [ ] Cache invalidation on write
- [ ] Queue monitoring dashboard
- [ ] Per-user rate limiting
- [ ] Implement archival strategy

---

## TIME ESTIMATE

| Task | Effort | Status |
|------|--------|--------|
| Add indexes | 10 min | — |
| Cache dashboard | 20 min | — |
| Media queue | 40 min | — |
| Media service | 40 min | — |
| Pagination rollout | 45 min | — |
| Job concurrency | 15 min | — |
| .env.example | 10 min | — |
| Testing & validation | 60 min | — |
| **TOTAL** | **240 min (4 hrs)** | — |

**With code review & QA: 6-8 hours**

