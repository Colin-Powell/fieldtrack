import express from 'express';
import cors from 'cors';
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
const app = express();
const port = process.env.PORT || 3000;
app.use(cors());
app.use(express.json());
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/sessions', sessionRoutes);
app.use('/api/v1/activities', activityRoutes);
app.use('/api/v1/media', mediaRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/reviews', reviewRoutes);
app.use('/api/v1/reports', reportRoutes);
// Also serve the storage folder statically so the frontend can display images
app.use('/storage', express.static('storage'));
// ── Health Check ──
app.get('/health', (req, res) => {
    res.json({ status: 'ok', message: 'FieldTrack Unified Backend is running' });
});
import { authenticate, authorizeRole } from './auth/auth.middleware.js';
// ── Supervisor Routes ──
app.get('/api/v1/supervisor/dashboard/stats', authenticate, authorizeRole(['SUPERVISOR', 'ADMIN']), async (req, res) => {
    try {
        const supervisorId = req.user?.userId;
        const supervisorProfile = await prisma.supervisorProfile.findUnique({
            where: { userId: supervisorId }
        });
        if (!supervisorProfile && req.user?.role !== 'ADMIN') {
            return res.json({ checkedOut: 0, checkedIn: 0, inField: 0 });
        }
        const whereClause = { role: 'STUDENT' };
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
            }
            else {
                checkedOut++;
            }
        }
        res.json({ checkedOut, checkedIn, inField });
    }
    catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
app.get('/api/v1/supervisor/students', authenticate, authorizeRole(['SUPERVISOR', 'ADMIN']), async (req, res) => {
    try {
        const supervisorId = req.user?.userId;
        const supervisorProfile = await prisma.supervisorProfile.findUnique({
            where: { userId: supervisorId }
        });
        const whereClause = { role: 'STUDENT' };
        if (req.user?.role !== 'ADMIN' && supervisorProfile) {
            whereClause.studentProfile = { supervisorId: supervisorProfile.id };
        }
        else if (req.user?.role !== 'ADMIN' && !supervisorProfile) {
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
            const activeSession = u.fieldSessions?.[0] ?? null;
            const latestLog = u.logs?.[0] ?? null;
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
                status: u.status, // ACTIVE | SUSPENDED | ARCHIVED
                avatarUrl: '',
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
    }
    catch (error) {
        console.error('Supervisor students error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
// ── GET /api/v1/supervisor/students/:id — full student profile ──
app.get('/api/v1/supervisor/students/:id', async (req, res) => {
    try {
        const id = req.params.id;
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
        if (!u)
            return res.status(404).json({ error: 'Student not found' });
        const sp = u.studentProfile;
        const sessions = u.fieldSessions ?? [];
        const activeSession = sessions.find((s) => !s.checkOutTime) ?? null;
        const isCheckedIn = !!activeSession;
        const logs = u.logs ?? [];
        const supervisorUser = sp?.supervisor?.user;
        res.json({
            id: u.id,
            name: u.name,
            email: u.email,
            status: u.status,
            avatarUrl: '',
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
            activities: logs.map((l) => ({
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
                evidence: (l.evidence ?? []).map((e) => ({
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
                totalEvidence: logs.reduce((acc, l) => acc + (l.evidence?.length ?? 0), 0),
                totalImages: logs.reduce((acc, l) => acc + (l.evidence?.length ?? 0), 0),
                totalVideos: 0,
                totalDocuments: 0,
                totalDistanceTravelled: sessions.reduce((acc, s) => acc + (s.distanceTravelled ?? 0), 0),
                totalTimeInField: sessions.reduce((acc, s) => acc + (s.durationSeconds ?? 0), 0),
                firstCheckIn: sessions.length > 0 ? sessions[sessions.length - 1].checkInTime.toISOString() : new Date().toISOString(),
                lastCheckOut: sessions.length > 0 && sessions[0].checkOutTime ? sessions[0].checkOutTime.toISOString() : new Date().toISOString(),
                averageGPSAccuracy: sessions.length > 0 ? sessions.reduce((acc, s) => acc + (s.averageAccuracy ?? 0), 0) / sessions.length : 0,
            },
            timeline: [
                ...sessions.map((s) => ({
                    time: s.checkInTime.toISOString(),
                    type: 'checkIn',
                    title: 'Checked In',
                    description: `Checked in (Accuracy: ${s.startAccuracy}m)`
                })),
                ...sessions.filter((s) => s.checkOutTime).map((s) => ({
                    time: s.checkOutTime.toISOString(),
                    type: 'checkOut',
                    title: 'Checked Out',
                    description: `Checked out`
                })),
                ...logs.map((l) => ({
                    time: l.timestamp.toISOString(),
                    type: 'activitySubmit',
                    title: l.title,
                    description: `Activity submitted with ${l.evidence?.length ?? 0} evidence files`
                }))
            ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()),
        });
    }
    catch (error) {
        console.error('Get student by ID error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
// ── Student Routes ──
app.post('/api/v1/student/location', async (req, res) => {
    res.status(501).json({ error: 'Not Implemented. Migrated to LocationPing.' });
});
// ── Admin Routes ──
app.get('/api/v1/admin/users', async (req, res) => {
    try {
        const users = await prisma.user.findMany();
        res.json(users);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal Server Error' });
    }
});
app.listen(Number(port), '0.0.0.0', () => {
    console.log(`[server]: Unified Server is running at http://0.0.0.0:${port}`);
});
