import express, { Request, Response } from 'express';
import path from 'path';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { RedisStore } from 'rate-limit-redis';
import { redis } from './utils/redis.js';
import morgan from 'morgan';
import { appLogger } from './utils/logger.js';
import { prisma } from './db.js';
import { authenticate } from './auth/auth.middleware.js';

import authRoutes from './auth/auth.routes.js';
import adminRoutes from './admins/admins.routes.js';
import dashboardRoutes from './dashboard/dashboard.routes.js';
import sessionRoutes from './sessions/session.routes.js';
import activityRoutes from './activities/activity.routes.js';
import mediaRoutes from './media/media.routes.js';
import notificationRoutes from './notifications/notification.routes.js';
import reviewRoutes from './reviews/review.routes.js';
import reportRoutes from './reports/reports.routes.js';
import settingsRoutes from './settings/settings.routes.js';
import developerRoutes from './developer/developer.routes.js';
import systemRoutes from './system/system.routes.js';
import { initializeDashboardSocket, broadcastDashboardEvent } from './developer/dashboard_events.js';
import { startScheduler } from './background/scheduler.js';
import { initFirebaseAdmin } from './firebase_admin.js';

const app = express();
app.set('trust proxy', 1); // Trust first proxy (Nginx) for accurate client IP
const port = process.env.PORT || 3000;
const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || 'http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080,http://127.0.0.1:8080,http://localhost:5173,http://127.0.0.1:5173').split(',').map((origin) => origin.trim()).filter(Boolean);
const isLocalDevOrigin = (origin: string) => /^https?:\/\/(localhost|127\.0\.0\.1)(?::\d+)?$/.test(origin);
const corsOptions = {
  origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
    if (!origin || allowedOrigins.includes(origin) || isLocalDevOrigin(origin)) {
      callback(null, true);
      return;
    }

    callback(null, false);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'x-platform', 'x-app-version', 'x-device-id', 'x-fingerprint'],
} satisfies cors.CorsOptions;

if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET must be configured before starting the backend.');
}

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL must be configured before starting the backend.');
}

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      baseUri: ["'self'"],
      objectSrc: ["'none'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      scriptSrcAttr: ["'none'"],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://cdnjs.cloudflare.com', 'https://fonts.googleapis.com'],
      imgSrc: ["'self'", 'data:'],
      fontSrc: ["'self'", 'https://cdnjs.cloudflare.com', 'https://fonts.gstatic.com'],
      connectSrc: ["'self'"],
      frameAncestors: ["'none'"],
      formAction: ["'self'"],
      upgradeInsecureRequests: [],
      workerSrc: ["'none'"],
    },
  },
  crossOriginResourcePolicy: { policy: 'same-origin' },
  frameguard: { action: 'deny' },
}));
app.use(cors(corsOptions));
app.use(express.json());

app.use((req: Request, res: Response, next: express.NextFunction) => {
  const originalJson = res.json.bind(res);

  res.json = ((body: unknown) => {
    if (body && typeof body === 'object' && !Array.isArray(body)) {
      const payload = body as Record<string, unknown>;
      if (typeof payload.error === 'string' && payload.error.trim().length > 0) {
        const normalized: Record<string, unknown> = { ...payload };

        if (typeof payload.message !== 'string' || payload.message.trim().length === 0) {
          normalized.message = payload.error;
        }

        if (payload.error === 'Internal server error' || payload.error === 'Internal Server Error' || payload.error === 'Unknown error') {
          normalized.error = 'Server error. Please try again later.';
        }

        if (payload.error === 'Unauthorized' || payload.error === 'Unauthorized: No token provided' || payload.error === 'Unauthorized: Invalid token') {
          normalized.error = 'Session expired. Please log in again.';
        }

        if (payload.error === 'Forbidden: Insufficient role permissions' || payload.error === 'Access denied.') {
          normalized.error = 'Access denied.';
        }

        return originalJson(normalized);
      }
    }

    return originalJson(body as any);
  }) as typeof res.json;

  next();
});

// Log HTTP requests using Morgan and Winston
app.use(morgan('combined', { stream: { write: (msg) => appLogger.info(msg.trim()) } }));

// Global Rate Limiter backed by Redis
const globalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // Limit each user/IP to 100 requests per minute
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests, please try again later',
  store: new RedisStore({
    sendCommand: (...args: string[]) => redis.call(args[0], ...args.slice(1)) as any,
  }),
  keyGenerator: (req) => {
    // If authenticated, use userId, otherwise fallback to IP
    return (req as any).user?.userId || req.ip;
  }
});
app.use('/api', globalLimiter);

app.put('/api/v1/fcm-token', authenticate, async (req: Request, res: Response) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    const trimmedToken = fcmToken.trim();

    // Check if user previously had no token (new registration vs refresh)
    const existingUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    const isNewToken = !existingUser?.fcmToken || existingUser.fcmToken !== trimmedToken;

    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: trimmedToken },
    });

    // Send a single summary push for unread notifications (only on new token registration)
    if (isNewToken) {
      const unreadCount = await prisma.notification.count({
        where: { recipientId: userId, isRead: false },
      });

      if (unreadCount > 0) {
        try {
          const { firebaseAdmin, getMessagingClient } = await import('./firebase_admin.js');
          if (firebaseAdmin?.apps?.length) {
            await getMessagingClient().send({
              token: trimmedToken,
              notification: {
                title: 'Notifications waiting',
                body: `You have ${unreadCount} unread notification${unreadCount === 1 ? '' : 's'}. Tap to view.`,
              },
              android: {
                priority: 'high',
                notification: {
                  channelId: 'high_importance_channel',
                  sound: 'default',
                },
              },
              apns: {
                headers: { 'apns-priority': '10' },
                payload: { aps: { sound: 'default', badge: unreadCount } },
              },
              data: {
                notificationType: 'UNREAD_SUMMARY',
                unreadCount: unreadCount.toString(),
              },
            });
            appLogger.info('Sent unread summary push', { userId, unreadCount });
          }
        } catch (pushError) {
          // Non-critical — don't fail the token registration
          appLogger.error('Failed to send unread summary push:', pushError);
        }
      }
    }

    appLogger.info('FCM token updated', { userId });
    res.json({ success: true, linked: true, message: 'FCM token linked to user' });
  } catch (error) {
    appLogger.error('Error updating FCM token:', error);
    res.status(500).json({ error: 'Failed to register FCM token' });
  }
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/sessions', sessionRoutes);
app.use('/api/v1/activities', activityRoutes);
app.use('/api/v1/media', mediaRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/reviews', reviewRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/developer', developerRoutes);
app.use('/api/v1/system', systemRoutes);

// ── Health Check ──
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'FieldTrack Unified Backend is running' });
});

app.get(/^\/developer-dashboard(\/.*)?$/, authenticate, async (req: Request, res: Response) => {
  if (req.user?.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Access denied.' });
  }

  res.sendFile(path.resolve(process.cwd(), 'src/developer/developer.html'));
});

app.get('/developer-login', (_req: Request, res: Response) => {
  res.sendFile(path.resolve(process.cwd(), 'src/developer/developer-login.html'));
});

import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const BASE_STORAGE_DIR = process.env.STORAGE_DIR
  ? path.resolve(process.env.STORAGE_DIR)
  : path.resolve(__dirname, '../storage');

// Serve the storage folder statically with caching and media streaming support
// IMPORTANT: This MUST come before the catch-all 404 handler
app.use('/storage', express.static(BASE_STORAGE_DIR, {
  maxAge: '30d',
  setHeaders: (res, filePath) => {
    // Ensure media files indicate they support byte range requests for streaming
    if (filePath.endsWith('.mp4') || filePath.endsWith('.mp3') || filePath.endsWith('.m4a')) {
      res.set('Accept-Ranges', 'bytes');
    }
    // Set proper cache headers
    res.set('Cache-Control', 'public, max-age=2592000, immutable');
  }
}));

// 404 and Error handlers moved to end of file

import { ensureEnvAdminAccount } from './admin-sync.js';



import { authorizeRole } from './auth/auth.middleware.js';

// ── Supervisor Routes ── (SUPERVISOR role only — strict RBAC)
app.get('/api/v1/supervisor/dashboard/stats', authenticate, authorizeRole(['SUPERVISOR']), async (req: Request, res: Response) => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId }
    });

    if (!supervisorProfile) {
      return res.json({ checkedOut: 0, checkedIn: 0, inField: 0 });
    }

    const students = await prisma.user.findMany({
      where: {
        role: 'STUDENT',
        studentProfile: { supervisorId: supervisorProfile.id },
      },
      include: {
        fieldSessions: {
          where: { checkOutTime: null }
        }
      }
    });

    let checkedIn = 0;
    let checkedOut = 0;
    let inField = 0;

    for (const s of students) {
      if (s.fieldSessions && s.fieldSessions.length > 0) {
        checkedIn++;
        inField++;
      } else {
        checkedOut++;
      }
    }

    res.json({ checkedOut, checkedIn, inField });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/api/v1/supervisor/students', authenticate, authorizeRole(['SUPERVISOR']), async (req: Request, res: Response) => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId }
    });

    if (!supervisorProfile) {
      // Supervisor has no profile yet — they have no students
      return res.json([]);
    }

    const students = await prisma.user.findMany({
      where: {
        role: 'STUDENT',
        studentProfile: { supervisorId: supervisorProfile.id },
      },
      include: {
        studentProfile: {
          include: {
            supervisor: {
              include: { user: true }
            }
          }
        },
        fieldSessions: {
          where: { checkOutTime: null },
          orderBy: { checkInTime: 'desc' },
          take: 1,
        },
        logs: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        }
      },
      orderBy: { createdAt: 'desc' },
    });

    const mapped = students.map((u) => {
      const sp = u.studentProfile;
      const activeSession = (u as any).fieldSessions?.[0] ?? null;
      const latestLog = (u as any).logs?.[0] ?? null;
      const supervisorUser = sp?.supervisor?.user;

      const isCheckedIn = !!activeSession;
      const fieldStatus = isCheckedIn ? 'In Field' : 'Offline';
      const lastActivity = latestLog?.timestamp
        ? new Date(latestLog.timestamp).toISOString()
        : null;

      return {
        id: u.id,
        name: u.name,
        email: u.email,
        status: u.status,
        avatarUrl: sp?.avatar ?? '',
        reg: sp?.registrationNo ?? '',
        programme: sp?.programme ?? '',
        department: sp?.department ?? '',
        faculty: sp?.faculty ?? '',
        topic: sp?.topic ?? '',
        checkInStatus: isCheckedIn ? 'Checked In' : 'Checked Out',
        fieldStatus,
        lastActivity,
        supervisorId: sp?.supervisorId ?? null,
        supervisorName: supervisorUser?.name ?? null,
        currentSession: activeSession
          ? {
              active: true,
              checkInTime: activeSession.checkInTime.toISOString(),
              checkOutTime: activeSession.checkOutTime?.toISOString() ?? null,
              latitude: activeSession.startLatitude ?? 0,
              longitude: activeSession.startLongitude ?? 0,
              accuracy: activeSession.startAccuracy ?? 0,
            }
          : null,
      };
    });

    res.json(mapped);
  } catch (error) {
    console.error('Supervisor students error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ── GET /api/v1/supervisor/students/:id — full student profile (SUPERVISOR only)
app.get('/api/v1/supervisor/students/:id', authenticate, authorizeRole(['SUPERVISOR']), async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const u = await prisma.user.findUnique({
      where: { id },
      include: {
        studentProfile: {
          include: {
            supervisor: { include: { user: true } }
          }
        },
        fieldSessions: {
          orderBy: { checkInTime: 'desc' },
          take: 10,
        },
        logs: {
          orderBy: { timestamp: 'desc' },
          take: 20,
          include: { evidence: true }
        },
      }
    });

    if (!u) return res.status(404).json({ error: 'Student not found' });

    const sp = u.studentProfile;
    const sessions = (u as any).fieldSessions ?? [];
    const activeSession = sessions.find((s: any) => !s.checkOutTime) ?? null;
    const isCheckedIn = !!activeSession;
    const logs = (u as any).logs ?? [];
    const supervisorUser = sp?.supervisor?.user;

    res.json({
      id: u.id,
      name: u.name,
      email: u.email,
      status: u.status,
      avatarUrl: sp?.avatar ?? '',
      reg: sp?.registrationNo ?? '',
      programme: sp?.programme ?? '',
      department: sp?.department ?? '',
      faculty: sp?.faculty ?? '',
      phone: sp?.phone ?? '',
      topic: sp?.topic ?? '',
      university: sp?.faculty ?? '',
      checkInStatus: isCheckedIn ? 'Checked In' : 'Checked Out',
      fieldStatus: isCheckedIn ? 'In Field' : 'Offline',
      lastActivity: logs[0]?.timestamp ?? null,
      supervisorId: sp?.supervisorId ?? null,
      supervisorName: supervisorUser?.name ?? null,
      supervisorEmail: supervisorUser?.email ?? null,
      currentSession: activeSession
        ? {
            active: true,
            checkInTime: activeSession.checkInTime.toISOString(),
            checkOutTime: activeSession.checkOutTime?.toISOString() ?? null,
            latitude: activeSession.startLatitude ?? 0,
            longitude: activeSession.startLongitude ?? 0,
            accuracy: activeSession.startAccuracy ?? 0,
          }
        : null,
      activities: logs.map((l: any) => ({
        id: l.id,
        title: l.title,
        description: l.description ?? '',
        status: l.status,
        startTime: l.timestamp.toISOString(),
        endTime: l.timestamp.toISOString(),
        duration: 0,
        category: '',
        methodology: l.methodology ?? '',
        objectives: l.objectives ?? '',
        findings: l.findings ?? '',
        remarks: l.remarks ?? '',
        location: {
          latitude: l.latitude ?? 0,
          longitude: l.longitude ?? 0,
          accuracy: l.gpsAccuracy ?? 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          capturedAt: l.timestamp.toISOString(),
          address: '',
        },
        evidence: (l.evidence ?? []).map((e: any) => ({
          id: e.id,
          type: e.type?.toLowerCase() ?? 'image',
          fileName: e.fileName ?? '',
          url: e.url ?? '',
          sizeMB: 0,
          uploadedAt: e.createdAt?.toISOString() ?? new Date().toISOString(),
          uploadedBy: u.name,
        })),
        review: null,
      })),
      statistics: {
        totalFieldDays: sessions.length,
        totalActivities: logs.length,
        totalReports: 0,
        totalEvidence: logs.reduce((acc: number, l: any) => acc + (l.evidence?.length ?? 0), 0),
        totalImages: logs.reduce((acc: number, l: any) => acc + (l.evidence?.length ?? 0), 0),
        totalVideos: 0,
        totalDocuments: 0,
        totalDistanceTravelled: sessions.reduce((acc: number, s: any) => acc + (s.distanceTravelled ?? 0), 0),
        totalTimeInField: sessions.reduce((acc: number, s: any) => acc + (s.durationSeconds ?? 0), 0),
        firstCheckIn: sessions.length > 0 ? sessions[sessions.length - 1].checkInTime.toISOString() : new Date().toISOString(),
        lastCheckOut: sessions.length > 0 && sessions[0].checkOutTime ? sessions[0].checkOutTime.toISOString() : new Date().toISOString(),
        averageGPSAccuracy: sessions.length > 0 ? sessions.reduce((acc: number, s: any) => acc + (s.averageAccuracy ?? 0), 0) / sessions.length : 0,
      },
      timeline: [
        ...sessions.map((s: any) => ({
          time: s.checkInTime.toISOString(),
          type: 'checkIn',
          title: 'Checked In',
          description: `Checked in (Accuracy: ${s.startAccuracy}m)`
        })),
        ...sessions.filter((s: any) => s.checkOutTime).map((s: any) => ({
          time: s.checkOutTime.toISOString(),
          type: 'checkOut',
          title: 'Checked Out',
          description: `Checked out`
        })),
        ...logs.map((l: any) => {
          const imageEvidence = l.evidence?.find((e: any) => e.mimeType?.startsWith('image/'));
          return {
            time: l.timestamp.toISOString(),
            type: 'activitySubmit',
            title: l.title,
            description: `Activity submitted with ${l.evidence?.length ?? 0} evidence files`,
            imageUrl: imageEvidence?.storagePath || undefined,
            activityId: l.id
          };
        })
      ].sort((a: any, b: any) => new Date(b.time).getTime() - new Date(a.time).getTime()),
    });
  } catch (error) {
    console.error('Get student by ID error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ── Student Routes ──
app.post('/api/v1/student/location', async (req: Request, res: Response) => {
  res.status(501).json({ error: 'Not Implemented. Migrated to LocationPing.' });
});

// NOTE: The admin users endpoint lives in admins.routes.ts (protected with authenticate + authorizeRole(['ADMIN']))
// The duplicate unprotected route has been intentionally removed.

app.use((req: Request, res: Response) => {
  res.status(404).json({
    status: 404,
    error: 'Resource not found.',
    errorCode: 'RESOURCE_NOT_FOUND',
    message: 'The requested endpoint could not be found.',
    path: req.originalUrl,
  });
});

app.use((err: any, req: Request, res: Response, next: express.NextFunction) => {
  const statusCode = Number.isFinite(err?.statusCode) ? Number(err.statusCode) : 500;
  const serverMessage = typeof err?.message === 'string' && err.message.trim().length > 0
    ? err.message
    : 'Something went wrong.';

  const response: Record<string, unknown> = {
    error: statusCode >= 500 ? 'Server error. Please try again later.' : serverMessage,
  };

  if (statusCode === 400 && Array.isArray(err?.details) && err.details.length > 0) {
    response.details = err.details;
    response.message = err.details[0]?.message ?? 'Please check the submitted data.';
  }

  if (statusCode === 401) {
    response.error = 'Session expired. Please log in again.';
  }

  if (statusCode === 403) {
    response.error = 'Access denied.';
  }

  if (statusCode === 404) {
    response.error = 'Resource not found.';
  }

  if (statusCode === 409) {
    response.error = 'Conflict detected. Please try again.';
  }

  if (statusCode === 422) {
    response.error = 'Invalid data submitted.';
  }

  return res.status(statusCode).json(response);
});

ensureEnvAdminAccount()
  .then(async () => {
    await initFirebaseAdmin();
    startScheduler();
    const server = app.listen(Number(port), '0.0.0.0', () => {
      console.log(`[server]: Unified Server is running at http://0.0.0.0:${port}`);
    });

initializeDashboardSocket(server);
  })
  .catch((error) => {
    console.error('Failed to ensure admin account from env:', error);
    process.exit(1);
  });
