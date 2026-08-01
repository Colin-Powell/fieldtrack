import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import { appLogger } from './utils/logger.js';
import { prisma } from './db.js';

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

const app = express();
app.set('trust proxy', 1); // Trust first proxy (Nginx) for accurate client IP
const port = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

// Log HTTP requests using Morgan and Winston
app.use(morgan('combined', { stream: { write: (msg) => appLogger.info(msg.trim()) } }));

// Global Rate Limiter
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests from this IP, please try again after 15 minutes',
});
app.use('/api', globalLimiter);

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

import { BASE_STORAGE_DIR } from './media/storage.service.js';

// Serve the storage folder statically with caching and media streaming support
app.use('/storage', express.static(BASE_STORAGE_DIR, {
  maxAge: '30d',
  setHeaders: (res, path, stat) => {
    res.set('Access-Control-Allow-Origin', '*');
    // Ensure media files indicate they support byte range requests for streaming
    if (path.endsWith('.mp4') || path.endsWith('.mp3') || path.endsWith('.m4a')) {
      res.set('Accept-Ranges', 'bytes');
    }
    // Set proper cache headers
    res.set('Cache-Control', 'public, max-age=2592000, immutable');
  }
}));



// ── Health Check ──
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'FieldTrack Unified Backend is running' });
});

import { authenticate, authorizeRole } from './auth/auth.middleware.js';

// ── Supervisor Routes ──
app.get('/api/v1/supervisor/dashboard/stats', authenticate, authorizeRole(['SUPERVISOR', 'ADMIN']), async (req: Request, res: Response) => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId }
    });

    if (!supervisorProfile && req.user?.role !== 'ADMIN') {
      return res.json({ checkedOut: 0, checkedIn: 0, inField: 0 });
    }

    const whereClause: any = { role: 'STUDENT' };
    if (req.user?.role !== 'ADMIN' && supervisorProfile) {
      whereClause.studentProfile = { supervisorId: supervisorProfile.id };
    }

    const students = await prisma.user.findMany({
      where: whereClause,
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

app.get('/api/v1/supervisor/students', authenticate, authorizeRole(['SUPERVISOR', 'ADMIN']), async (req: Request, res: Response) => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId }
    });

    const whereClause: any = { role: 'STUDENT' };
    if (req.user?.role !== 'ADMIN' && supervisorProfile) {
      whereClause.studentProfile = { supervisorId: supervisorProfile.id };
    } else if (req.user?.role !== 'ADMIN' && !supervisorProfile) {
      // If supervisor has no profile yet, they have no students.
      return res.json([]);
    }

    const students = await prisma.user.findMany({
      where: whereClause,
      include: {
        studentProfile: {
          include: {
            supervisor: {
              include: { user: true }
            }
          }
        },
        // Active session — determines checkInStatus
        fieldSessions: {
          where: { checkOutTime: null },
          orderBy: { checkInTime: 'desc' },
          take: 1,
        },
        // Latest activity — for lastActivity timestamp
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

      // Check-in status: "Checked In" if there's an active (open) session
      const isCheckedIn = !!activeSession;

      // Field status: if actively checked in, they're "In Field"; otherwise "Offline"
      const fieldStatus = isCheckedIn ? 'In Field' : 'Offline';

      // Last activity: ISO timestamp of most recent field log
      const lastActivity = latestLog?.timestamp
        ? new Date(latestLog.timestamp).toISOString()
        : null;

      return {
        id: u.id,
        name: u.name,
        email: u.email,
        status: u.status,             // ACTIVE | SUSPENDED | ARCHIVED
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

// ── GET /api/v1/supervisor/students/:id — full student profile ──
app.get('/api/v1/supervisor/students/:id', async (req: Request, res: Response) => {
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
      topic: sp?.topic ?? '',
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
            imageUrl: imageEvidence?.storagePath || undefined
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

// ── Admin Routes ──
app.get('/api/v1/admin/users', async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.listen(Number(port), '0.0.0.0', () => {
  console.log(`[server]: Unified Server is running at http://0.0.0.0:${port}`);
});
