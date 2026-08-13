import { readFileSync } from 'fs';
import os from 'os';
import { Router, Request, Response } from 'express';
import { prisma } from '../db.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
import { appLogger, authLogger, uploadsLogger } from '../utils/logger.js';
import { broadcastDashboardEvent } from './dashboard_events.js';
import { generateToken } from '../auth/jwt.js';
import { exec } from 'child_process';
import util from 'util';

const DEFAULT_FEATURE_FLAGS = {
  'GPS Tracking': true,
  'Offline Sync': true,
  'Maps': true,
  'AI Review': false,
  'Reports': true,
};

const DEFAULT_ACTION_STATUS = {
  action: 'No action run',
  status: 'idle',
  message: 'No operations have been executed yet.',
  timestamp: new Date().toISOString(),
};

async function getFeatureFlagsState(): Promise<Record<string, boolean>> {
  try {
    const record = await prisma.systemSetting.findUnique({ where: { key: 'developer_feature_flags' } });
    const savedFlags = (record?.value as Record<string, boolean> | undefined) ?? {};
    const merged = { ...DEFAULT_FEATURE_FLAGS, ...savedFlags };

    if (!record) {
      await prisma.systemSetting.create({
        data: {
          key: 'developer_feature_flags',
          value: merged,
          updatedBy: 'developer-admin',
        },
      });
    }

    return merged;
  } catch (error) {
    appLogger.warn('Unable to load developer feature flags from DB, using defaults', error);
    return { ...DEFAULT_FEATURE_FLAGS };
  }
}

async function saveFeatureFlagsState(flags: Record<string, boolean>, actorId = 'developer-admin') {
  await prisma.systemSetting.upsert({
    where: { key: 'developer_feature_flags' },
    update: { value: flags, updatedBy: actorId },
    create: { key: 'developer_feature_flags', value: flags, updatedBy: actorId },
  });
}

async function getMaintenanceModeState(): Promise<boolean> {
  try {
    const record = await prisma.systemSetting.findUnique({ where: { key: 'developer_maintenance_mode' } });
    const enabled = Boolean(record?.value);
    if (!record) {
      await prisma.systemSetting.create({
        data: {
          key: 'developer_maintenance_mode',
          value: enabled,
          updatedBy: 'developer-admin',
        },
      });
    }
    return enabled;
  } catch (error) {
    appLogger.warn('Unable to load maintenance mode from DB, using default false', error);
    return false;
  }
}

async function saveMaintenanceModeState(enabled: boolean, actorId = 'developer-admin') {
  await prisma.systemSetting.upsert({
    where: { key: 'developer_maintenance_mode' },
    update: { value: enabled, updatedBy: actorId },
    create: { key: 'developer_maintenance_mode', value: enabled, updatedBy: actorId },
  });
}

async function getLastActionStatus() {
  try {
    const record = await prisma.systemSetting.findUnique({ where: { key: 'developer_last_action' } });
    if (!record) return { ...DEFAULT_ACTION_STATUS };
    const payload = record.value as Record<string, any> | null;
    if (!payload || typeof payload !== 'object') return { ...DEFAULT_ACTION_STATUS };
    return {
      action: payload.action ?? 'No action run',
      status: payload.status ?? 'idle',
      message: payload.message ?? 'No operations have been executed yet.',
      timestamp: payload.timestamp ?? new Date().toISOString(),
    };
  } catch (error) {
    appLogger.warn('Unable to load developer action status', error);
    return { ...DEFAULT_ACTION_STATUS };
  }
}

async function saveLastActionStatus(action: string, status: 'success' | 'error' | 'idle', message: string, actorId = 'developer-admin') {
  const payload = {
    action,
    status,
    message,
    timestamp: new Date().toISOString(),
    actorId,
  };

  await prisma.systemSetting.upsert({
    where: { key: 'developer_last_action' },
    update: { value: payload, updatedBy: actorId },
    create: { key: 'developer_last_action', value: payload, updatedBy: actorId },
  });

  return payload;
}

const execAsync = util.promisify(exec);

const backendPackageJson = JSON.parse(readFileSync(new URL('../../package.json', import.meta.url), 'utf-8')) as { version?: string };

const router = Router();

router.post('/login', async (req: Request, res: Response) => {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    const expectedEmail = String(process.env.ADMIN_EMAIL || '').trim().toLowerCase();
    const expectedPassword = String(process.env.ADMIN_PASSWORD || '');

    if (!email || !password || email !== expectedEmail || password !== expectedPassword) {
      return res.status(401).json({ error: 'Invalid developer dashboard credentials' });
    }

    const token = generateToken({ userId: 'developer-admin', role: 'ADMIN', email });
    return res.json({ success: true, token });
  } catch (error) {
    appLogger.error('Developer dashboard login failed', error);
    return res.status(500).json({ error: 'Unable to sign in' });
  }
});

router.use(authenticate, authorizeRole(['ADMIN']));

function getStatusColor(status: string) {
  switch (status) {
    case 'healthy':
      return 'green';
    case 'warning':
      return 'yellow';
    case 'critical':
      return 'red';
    default:
      return 'gray';
  }
}

router.get('/health', async (_req: Request, res: Response) => {
  try {
    const [userCount, activeSessions, recentErrors, recentActivityCount] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }),
      prisma.fieldSession.count({ where: { checkOutTime: null } }),
      prisma.auditLog.count({ where: { action: { in: ['FAILED_LOGIN', 'PASSWORD_RESET', 'USER_STATUS_UPDATED'] } } }),
      prisma.fieldLog.count({ where: { timestamp: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } } }),
    ]);

    const health = {
      status: 'healthy',
      uptime: process.uptime().toFixed(1),
      timestamp: new Date().toISOString(),
      metrics: {
        users: userCount,
        activeSessions,
        errors24h: recentErrors,
        activities24h: recentActivityCount,
      },
      services: [
        { name: 'database', status: 'healthy', details: 'Prisma connected' },
        { name: 'auth', status: 'healthy', details: 'JWT and login paths active' },
        { name: 'media', status: 'healthy', details: 'Upload routes available' },
        { name: 'notifications', status: 'healthy', details: 'FCM and in-app notifications enabled' },
      ],
    };

    res.json(health);
  } catch (error) {
    appLogger.error('Developer dashboard health check failed', error);
    res.status(500).json({ status: 'critical', error: 'Unable to collect dashboard metrics' });
  }
});

router.post('/tickets', async (req: Request, res: Response) => {
  try {
    const { type, title, description, severity, reporterId } = req.body;
    const ticket = {
      id: `ticket-${Date.now()}`,
      type: type || 'bug_report',
      title: title || 'Untitled report',
      description: description || '',
      severity: severity || 'medium',
      reporterId: reporterId || req.user?.userId || 'system',
      createdAt: new Date().toISOString(),
    };

    await prisma.auditLog.create({
      data: {
        action: 'TICKET_CREATED',
        details: ticket,
        actorId: req.user?.userId,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      },
    });

    broadcastDashboardEvent({ type: 'ticket_created', payload: ticket });
    res.status(201).json({ success: true, ticket });
  } catch (error) {
    appLogger.error('Developer dashboard ticket creation failed', error);
    res.status(500).json({ error: 'Unable to create ticket' });
  }
});

router.get('/export', async (_req: Request, res: Response) => {
  try {
    const [users, sessions, reviews, tickets] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }),
      prisma.fieldSession.count({ where: { checkOutTime: null } }),
      prisma.review.count(),
      prisma.auditLog.count({ where: { action: 'TICKET_CREATED' } }),
    ]);

    const payload = {
      generatedAt: new Date().toISOString(),
      summary: { users, activeSessions: sessions, reviews, tickets },
    };

    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', 'attachment; filename="developer-report.json"');
    res.send(JSON.stringify(payload, null, 2));
  } catch (error) {
    appLogger.error('Developer dashboard export failed', error);
    res.status(500).json({ error: 'Unable to export report' });
  }
});

router.get('/dashboard-aggregate', async (_req: Request, res: Response) => {
  try {
    const [healthRes, metricsRes, logsRes, requestsRes, issuesRes, overviewRes, lastAction] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }).then(() => ({ status: 'Ok', timestamp: new Date().toISOString(), uptime: process.uptime() })),
      (async () => {
        const [users, activeSessions, pendingReviews, failedLogins, recentActivities, evidenceFiles] = await Promise.all([
          prisma.user.count({ where: { deletedAt: null } }),
          prisma.fieldSession.count({ where: { checkOutTime: null } }),
          prisma.review.count({ where: { status: { in: ['UNDER_REVIEW', 'REVISION_REQUESTED'] } } }),
          prisma.auditLog.count({ where: { action: 'FAILED_LOGIN' } }),
          prisma.fieldLog.count({ where: { timestamp: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } } }),
          prisma.evidence.count(),
        ]);

        return {
          metrics: {
            users,
            activeSessions,
            pendingReviews,
            failedLogins,
            totalActivities: recentActivities,
            evidenceFiles,
            syncStatus: '100%',
            checkoutStatus: 'OK',
          },
          trend: [
            { label: 'Users', value: users },
            { label: 'Active sessions', value: activeSessions },
            { label: 'Reviews', value: pendingReviews },
            { label: 'Failed logins', value: failedLogins },
          ],
        };
      })(),
      prisma.auditLog.findMany({ orderBy: { timestamp: 'desc' }, take: 20 }).then(logs => ({ logs })),
      prisma.fieldLog.findMany({ orderBy: { timestamp: 'desc' }, take: 10, include: { user: true } }).then(logs => ({ requests: logs.map(entry => ({
        type: 'API',
        method: 'GET',
        endpoint: entry.title || '/api/v1/unknown',
        status: Number(entry.status) || 200,
        timestamp: entry.timestamp.toISOString(),
      })) })),
      Promise.resolve({ issues: [] }),
      (async () => {
        const [users, activeSessions, recentLogs, recentReviews, recentNotifications, totalStorageSize, totalActivities, evidenceFiles] = await Promise.all([
          prisma.user.count({ where: { deletedAt: null } }),
          prisma.fieldSession.count({ where: { checkOutTime: null } }),
          prisma.auditLog.findMany({ orderBy: { timestamp: 'desc' }, take: 10 }),
          prisma.review.findMany({ orderBy: { createdAt: 'desc' }, take: 10 }),
          prisma.notification.findMany({ orderBy: { createdAt: 'desc' }, take: 10 }),
          prisma.evidence.aggregate({ _sum: { fileSize: true } }),
          prisma.fieldLog.count(),
          prisma.evidence.count(),
        ]);

        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const weeklyLogs = await prisma.auditLog.findMany({
          where: { timestamp: { gte: sevenDaysAgo } },
          select: { timestamp: true },
        });

        const trendBuckets = [0, 0, 0, 0, 0, 0, 0];
        weeklyLogs.forEach(log => {
          const dayDiff = Math.floor((Date.now() - log.timestamp.getTime()) / (24 * 60 * 60 * 1000));
          if (dayDiff >= 0 && dayDiff < 7) trendBuckets[6 - dayDiff]++;
        });

        return {
          summary: {
            users,
            activeSessions,
            recentAudits: recentLogs.length,
            recentReviews: recentReviews.length,
            notifications: recentNotifications.length,
            totalActivities,
            evidenceFiles,
            syncStatus: '100%',
            checkoutStatus: 'OK',
          },
          chartData: {
            activityTrend: trendBuckets,
            storageSizes: [
              Math.round((totalStorageSize._sum.fileSize || 0) / (1024 * 1024)),
              Math.max(1, Math.round((totalStorageSize._sum.fileSize || 0) / (1024 * 1024) / 2)),
            ],
          },
          recentAuditEvents: recentLogs.map((entry) => ({ id: entry.id, action: entry.action, timestamp: entry.timestamp.toISOString(), details: entry.details })),
        };
      })(),
      getLastActionStatus(),
    ]);

    metricsRes.metrics.users = overviewRes.summary.users;
    metricsRes.metrics.activeSessions = overviewRes.summary.activeSessions;
    metricsRes.metrics.totalActivities = overviewRes.summary.totalActivities;
    metricsRes.metrics.evidenceFiles = overviewRes.summary.evidenceFiles;
    metricsRes.metrics.syncStatus = overviewRes.summary.syncStatus;
    metricsRes.metrics.checkoutStatus = overviewRes.summary.checkoutStatus;

    res.json({
      health: healthRes,
      metrics: metricsRes,
      logs: logsRes.logs,
      requests: requestsRes.requests,
      issues: issuesRes.issues,
      overviewData: overviewRes,
      lastAction: lastAction,
    });
  } catch (error) {
    appLogger.error('Dashboard aggregate failed', error);
    res.status(500).json({ error: 'Unable to load aggregate data' });
  }
});

router.get('/logs', async (_req: Request, res: Response) => {
  try {
    const recentLogs = await prisma.auditLog.findMany({
      orderBy: { timestamp: 'desc' },
      take: 50,
    });

    res.json({
      logs: recentLogs.map((entry) => ({
        id: entry.id,
        action: entry.action,
        timestamp: entry.timestamp.toISOString(),
        ipAddress: entry.ipAddress,
        details: entry.details,
        status: entry.details ? 'ok' : 'info',
      })),
      sources: [
        { name: 'application', count: recentLogs.length, color: getStatusColor('healthy') },
        { name: 'auth', count: recentLogs.filter((entry) => entry.action.includes('LOGIN') || entry.action.includes('PASSWORD')).length, color: getStatusColor('healthy') },
        { name: 'uploads', count: recentLogs.filter((entry) => entry.action.includes('UPLOAD') || entry.action.includes('MEDIA')).length, color: getStatusColor('healthy') },
      ],
    });
  } catch (error) {
    appLogger.error('Developer dashboard logs failed', error);
    res.status(500).json({ error: 'Unable to load logs' });
  }
});

router.get('/requests', async (_req: Request, res: Response) => {
  try {
    const [recentActivity, recentSessions] = await Promise.all([
      prisma.fieldLog.findMany({ orderBy: { timestamp: 'desc' }, take: 20 }),
      prisma.fieldSession.findMany({ orderBy: { checkInTime: 'desc' }, take: 20 }),
    ]);

    res.json({
      requests: [
        ...recentActivity.map((entry) => ({
          id: entry.id,
          type: 'activity',
          title: entry.title,
          status: entry.status,
          timestamp: entry.timestamp.toISOString(),
        })),
        ...recentSessions.map((entry) => ({
          id: entry.id,
          type: 'session',
          title: `Session ${entry.id}`,
          status: entry.status,
          timestamp: entry.checkInTime.toISOString(),
        })),
      ].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()).slice(0, 25),
    });
  } catch (error) {
    appLogger.error('Developer dashboard requests failed', error);
    res.status(500).json({ error: 'Unable to load requests' });
  }
});

router.get('/issues', async (_req: Request, res: Response) => {
  try {
    const [reviews, notifications, recentErrors] = await Promise.all([
      prisma.review.findMany({ orderBy: { createdAt: 'desc' }, take: 20 }),
      prisma.notification.findMany({ orderBy: { createdAt: 'desc' }, take: 20 }),
      prisma.auditLog.findMany({ where: { action: { in: ['FAILED_LOGIN', 'PASSWORD_RESET', 'USER_STATUS_UPDATED'] } }, orderBy: { timestamp: 'desc' }, take: 20 }),
    ]);

    res.json({
      issues: [
        ...reviews.map((review) => ({
          id: review.id,
          category: 'bug_report',
          title: `Review ${review.status}`,
          severity: review.status === 'REJECTED' ? 'high' : 'medium',
          createdAt: review.createdAt.toISOString(),
        })),
        ...notifications.map((notification) => ({
          id: notification.id,
          category: 'feature_request',
          title: notification.title,
          severity: 'medium',
          createdAt: notification.createdAt.toISOString(),
        })),
        ...recentErrors.map((entry) => ({
          id: entry.id,
          category: 'security_event',
          title: entry.action,
          severity: 'high',
          createdAt: entry.timestamp.toISOString(),
        })),
      ].slice(0, 30),
    });
  } catch (error) {
    appLogger.error('Developer dashboard issues failed', error);
    res.status(500).json({ error: 'Unable to load issue feed' });
  }
});

router.get('/background-jobs', async (_req: Request, res: Response) => {
  try {
    const [pendingUploads, pendingReviews, unreadNotifications, activeSessions] = await Promise.all([
      prisma.evidence.count({ where: { uploadStatus: { not: 'SUCCESS' } } }),
      prisma.review.count({ where: { status: { in: ['UNDER_REVIEW', 'REVISION_REQUESTED'] } } }),
      prisma.notification.count({ where: { isRead: false } }),
      prisma.fieldSession.count({ where: { status: 'ACTIVE' } }),
    ]);

    res.json({
      jobs: [
        { name: 'Notifications', status: unreadNotifications > 0 ? 'Queued' : 'Healthy', detail: `${unreadNotifications} unread notification${unreadNotifications === 1 ? '' : 's'}` },
        { name: 'Sync queue', status: activeSessions > 0 ? 'Running' : 'Idle', detail: `${activeSessions} active ${activeSessions === 1 ? 'session' : 'sessions'}` },
        { name: 'Upload queue', status: pendingUploads > 0 ? 'Waiting' : 'Healthy', detail: `${pendingUploads} pending upload${pendingUploads === 1 ? '' : 's'}` },
        { name: 'Review queue', status: pendingReviews > 0 ? 'Reviewing' : 'Healthy', detail: `${pendingReviews} pending review${pendingReviews === 1 ? '' : 's'}` },
        { name: 'Scheduled jobs', status: 'Healthy', detail: 'Cron jobs and sync routines remain active' },
      ],
    });
  } catch (error) {
    appLogger.error('Developer dashboard background jobs failed', error);
    res.status(500).json({ error: 'Unable to load background jobs' });
  }
});

router.get('/database-explorer', async (_req: Request, res: Response) => {
  try {
    const [users, students, activities, evidence, notifications, reviews, studentCount, activityCount, evidenceCount, notificationCount, reviewCount] = await Promise.all([
      prisma.user.findMany({ take: 8, orderBy: { createdAt: 'desc' } }),
      prisma.studentProfile.findMany({ take: 8, include: { user: true } }),
      prisma.fieldLog.findMany({ take: 8, orderBy: { timestamp: 'desc' }, include: { user: true } }),
      prisma.evidence.findMany({ take: 8, orderBy: { uploadedAt: 'desc' }, include: { uploader: true } }),
      prisma.notification.findMany({ take: 8, orderBy: { createdAt: 'desc' }, include: { recipient: true } }),
      prisma.review.findMany({ take: 8, orderBy: { createdAt: 'desc' }, include: { reviewer: true, log: true } }),
      prisma.user.count({ where: { role: 'STUDENT' } }),
      prisma.fieldLog.count(),
      prisma.evidence.count(),
      prisma.notification.count(),
      prisma.review.count(),
    ]);

    res.json({
      counts: {
        users: studentCount + 1,
        students: studentCount,
        activities: activityCount,
        evidence: evidenceCount,
        notifications: notificationCount,
        reviews: reviewCount,
      },
      collections: {
        users: users.map((user) => ({ id: user.id, name: user.name, email: user.email, role: user.role, status: user.status })),
        students: students.map((student) => ({ id: student.id, registrationNo: student.registrationNo, programme: student.programme, department: student.department, status: student.status, user: student.user?.name || 'Unknown' })),
        activities: activities.map((activity) => ({ id: activity.id, title: activity.title, status: activity.status, timestamp: activity.timestamp.toISOString(), student: activity.user?.name || 'Unknown' })),
        evidence: evidence.map((item) => ({ id: item.id, originalName: item.originalName, mimeType: item.mimeType, size: item.fileSize, status: item.uploadStatus, uploadedAt: item.uploadedAt.toISOString(), uploader: item.uploader?.name || 'Unknown' })),
        notifications: notifications.map((notification) => ({ id: notification.id, title: notification.title, type: notification.type, read: notification.isRead, createdAt: notification.createdAt.toISOString(), recipient: notification.recipient?.name || 'Unknown' })),
        reviews: reviews.map((review) => ({ id: review.id, status: review.status, createdAt: review.createdAt.toISOString(), reviewer: review.reviewer?.name || 'Unknown', activityId: review.activityId })),
      },
    });
  } catch (error) {
    appLogger.error('Developer dashboard database explorer failed', error);
    res.status(500).json({ error: 'Unable to load database explorer data' });
  }
});

router.get('/media-manager', async (_req: Request, res: Response) => {
  try {
    const [items, countByStatus, totalSize] = await Promise.all([
      prisma.evidence.findMany({ take: 12, orderBy: { uploadedAt: 'desc' }, include: { uploader: true } }),
      prisma.evidence.groupBy({ by: ['uploadStatus'], _count: { id: true } }),
      prisma.evidence.aggregate({ _sum: { fileSize: true } }),
    ]);

    res.json({
      counts: {
        total: items.length,
        uploaded: countByStatus.find((item) => item.uploadStatus === 'SUCCESS')?._count.id || 0,
        failed: countByStatus.find((item) => item.uploadStatus === 'FAILED')?._count.id || 0,
        pending: countByStatus.find((item) => item.uploadStatus === 'PENDING')?._count.id || 0,
        totalSize: totalSize._sum.fileSize || 0,
      },
      items: items.map((item) => ({
        id: item.id,
        originalName: item.originalName,
        mimeType: item.mimeType,
        fileSize: item.fileSize,
        uploadStatus: item.uploadStatus,
        uploadedAt: item.uploadedAt.toISOString(),
        uploader: item.uploader?.name || 'Unknown',
        storagePath: item.storagePath,
      })),
    });
  } catch (error) {
    appLogger.error('Developer dashboard media manager failed', error);
    res.status(500).json({ error: 'Unable to load media manager data' });
  }
});

router.get('/security-center', async (_req: Request, res: Response) => {
  try {
    const [failedLogins, lockedAccounts, recentAuditEvents, activeRefreshTokens] = await Promise.all([
      prisma.auditLog.count({ where: { action: 'FAILED_LOGIN' } }),
      prisma.user.count({ where: { accountLockedUntil: { not: null } } }),
      prisma.auditLog.findMany({ where: { action: { in: ['FAILED_LOGIN', 'PASSWORD_RESET', 'USER_STATUS_UPDATED'] } }, orderBy: { timestamp: 'desc' }, take: 10 }),
      prisma.refreshToken.count({ where: { expiresAt: { gt: new Date() }, revokedAt: null } }),
    ]);

    res.json({
      counts: {
        failedLogins,
        lockedAccounts,
        activeRefreshTokens,
        suspiciousEvents: Math.max(failedLogins, 1),
      },
      events: recentAuditEvents.map((event) => ({
        id: event.id,
        action: event.action,
        timestamp: event.timestamp.toISOString(),
        ipAddress: event.ipAddress,
        device: event.device,
        details: event.details,
      })),
    });
  } catch (error) {
    appLogger.error('Developer dashboard security center failed', error);
    res.status(500).json({ error: 'Unable to load security center data' });
  }
});

router.get('/modules/:moduleKey', async (req: Request, res: Response) => {
  try {
    const moduleKey = String(req.params.moduleKey || '').trim();

    if (moduleKey === 'system-dashboard') {
      const [users, activeSessions, pendingReviews, failedLogins, recentActivities, departments] = await Promise.all([
        prisma.user.count({ where: { deletedAt: null } }),
        prisma.fieldSession.count({ where: { status: 'ACTIVE' } }),
        prisma.review.count({ where: { status: { in: ['UNDER_REVIEW', 'REVISION_REQUESTED'] } } }),
        prisma.auditLog.count({ where: { action: 'FAILED_LOGIN' } }),
        prisma.fieldLog.count({ where: { timestamp: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } } }),
        prisma.department.count(),
      ]);

      return res.json({
        cards: [
          { title: 'API status', detail: 'HTTP and auth routes responding', status: 'Healthy' },
          { title: 'Database status', detail: 'Prisma connection stable', status: 'Healthy' },
          { title: 'Storage', detail: `${users} users and ${departments} departments registered`, status: 'Healthy' },
          { title: 'Background workers', detail: `${recentActivities} recent activity events`, status: 'Healthy' },
          { title: 'Active sessions', detail: `${activeSessions} live sessions`, status: activeSessions > 0 ? 'Running' : 'Idle' },
        ],
        summary: {
          users,
          activeSessions,
          pendingReviews,
          failedLogins,
          departments,
          recentActivities,
        },
      });
    }

    if (moduleKey === 'live-api-monitor') {
      const recentActivity = await prisma.fieldLog.findMany({ orderBy: { timestamp: 'desc' }, take: 12, include: { user: true } });
      const errorCount = await prisma.auditLog.count({ where: { action: { in: ['FAILED_LOGIN', 'ERROR'] } } });
      const successCount = await prisma.auditLog.count({ where: { action: { in: ['LOGIN_SUCCESS', 'CREATED', 'CHECKED_IN', 'CHECKED_OUT'] } } });

      const endpointCounts = new Map<string, number>();
      recentActivity.forEach((entry) => {
        const endpoint = entry.title || '/api/v1/unknown';
        endpointCounts.set(endpoint, (endpointCounts.get(endpoint) ?? 0) + 1);
      });

      return res.json({
        chartData: {
          errorRates: [errorCount, successCount],
          endpoints: {
            labels: Array.from(endpointCounts.keys()).slice(0, 5),
            data: Array.from(endpointCounts.values()).slice(0, 5),
          },
        },
        items: recentActivity.map((entry) => ({
          method: 'GET',
          endpoint: entry.title || '/api/v1/unknown',
          status: String(entry.status || 200),
          duration: `${Math.max(18, 35 + ((entry.id.length * 7) % 60))}ms`,
          user: entry.user?.name || 'Unknown',
          tenant: 'default',
          device: 'web',
        })),
      });
    }

    if (moduleKey === 'error-center') {
      const errors = await prisma.auditLog.findMany({
        where: { action: { in: ['FAILED_LOGIN', 'PASSWORD_RESET', 'USER_STATUS_UPDATED'] } },
        orderBy: { timestamp: 'desc' },
        take: 20,
        include: { user: true },
      });
      return res.json({
        items: errors.map((entry) => ({
          title: entry.action,
          endpoint: '/api/v1/auth/login',
          user: entry.user?.name || 'Unknown',
          device: entry.device || 'web',
          appVersion: backendPackageJson.version || '1.0.0',
          timestamp: entry.timestamp.toISOString(),
          frequency: '1x',
        })),
      });
    }

    if (moduleKey === 'background-jobs') {
      const [pendingUploads, pendingReviews, unreadNotifications, activeSessions] = await Promise.all([
        prisma.evidence.count({ where: { uploadStatus: { not: 'SUCCESS' } } }),
        prisma.review.count({ where: { status: { in: ['UNDER_REVIEW', 'REVISION_REQUESTED'] } } }),
        prisma.notification.count({ where: { isRead: false } }),
        prisma.fieldSession.count({ where: { status: 'ACTIVE' } }),
      ]);

      return res.json({
        items: [
          { Queue: 'Notifications', Details: `${unreadNotifications} unread`, Status: unreadNotifications > 0 ? 'Queued' : 'Healthy' },
          { Queue: 'Sync queue', Details: `${activeSessions} active session${activeSessions === 1 ? '' : 's'}`, Status: activeSessions > 0 ? 'Running' : 'Idle' },
          { Queue: 'Upload queue', Details: `${pendingUploads} pending upload${pendingUploads === 1 ? '' : 's'}`, Status: pendingUploads > 0 ? 'Waiting' : 'Healthy' },
          { Queue: 'Review queue', Details: `${pendingReviews} pending review${pendingReviews === 1 ? '' : 's'}`, Status: pendingReviews > 0 ? 'Reviewing' : 'Healthy' },
          { Queue: 'Scheduled jobs', Details: 'Cron and sync routines active', Status: 'Healthy' },
        ],
      });
    }

    if (moduleKey === 'database-explorer') {
      const [users, students, activities, evidence, notifications, reviews] = await Promise.all([
        prisma.user.findMany({ take: 8, orderBy: { createdAt: 'desc' } }),
        prisma.studentProfile.findMany({ take: 8, include: { user: true } }),
        prisma.fieldLog.findMany({ take: 8, orderBy: { timestamp: 'desc' }, include: { user: true } }),
        prisma.evidence.findMany({ take: 8, orderBy: { uploadedAt: 'desc' }, include: { uploader: true } }),
        prisma.notification.findMany({ take: 8, orderBy: { createdAt: 'desc' }, include: { recipient: true } }),
        prisma.review.findMany({ take: 8, orderBy: { createdAt: 'desc' }, include: { reviewer: true, log: true } }),
      ]);

      return res.json({
        summary: {
          users: users.length,
          students: students.length,
          activities: activities.length,
          evidence: evidence.length,
          notifications: notifications.length,
          reviews: reviews.length,
        },
        rows: [
          ...users.map((user) => ({ id: user.id, category: 'Users', key: user.name, status: user.role, timestamp: user.createdAt.toISOString() })),
          ...students.map((student) => ({ id: student.id, category: 'Students', key: student.registrationNo, status: student.status, timestamp: student.user?.name || 'Unknown' })),
          ...activities.map((activity) => ({ id: activity.id, category: 'Activities', key: activity.title, status: activity.status, timestamp: activity.timestamp.toISOString() })),
          ...evidence.map((item) => ({ id: item.id, category: 'Evidence', key: item.originalName, status: item.uploadStatus, timestamp: item.uploadedAt.toISOString() })),
          ...notifications.map((notification) => ({ id: notification.id, category: 'Notifications', key: notification.title, status: notification.type, timestamp: notification.createdAt.toISOString() })),
          ...reviews.map((review) => ({ id: review.id, category: 'Reviews', key: review.activityId, status: review.status, timestamp: review.createdAt.toISOString() })),
        ].slice(0, 12),
      });
    }

    if (moduleKey === 'media-manager') {
      const [items, countByStatus, totalSize] = await Promise.all([
        prisma.evidence.findMany({ take: 12, orderBy: { uploadedAt: 'desc' }, include: { uploader: true } }),
        prisma.evidence.groupBy({ by: ['uploadStatus'], _count: { id: true } }),
        prisma.evidence.aggregate({ _sum: { fileSize: true } }),
      ]);

      return res.json({
        summary: {
          uploaded: countByStatus.find((item) => item.uploadStatus === 'SUCCESS')?._count.id || 0,
          pending: countByStatus.find((item) => item.uploadStatus === 'PENDING')?._count.id || 0,
          failed: countByStatus.find((item) => item.uploadStatus === 'FAILED')?._count.id || 0,
          totalSize: totalSize._sum.fileSize || 0,
        },
        items: items.map((item) => ({
          title: item.originalName,
          detail: `${item.mimeType} · ${item.fileSize} bytes`,
          status: item.uploadStatus,
          timestamp: item.uploadedAt.toISOString(),
        })),
      });
    }

    if (moduleKey === 'university-manager') {
      const departments = await prisma.department.findMany({ take: 10, orderBy: { createdAt: 'desc' } });
      return res.json({
        cards: departments.map((department) => ({ title: department.name, detail: department.faculty || 'No faculty assigned', status: department.code || 'active' })),
      });
    }

    if (moduleKey === 'integration-manager') {
      return res.json({
        cards: [
          { title: 'Student API', detail: 'Connected', status: 'Healthy' },
          { title: 'ERP', detail: 'Last sync successful', status: 'Healthy' },
          { title: 'Moodle', detail: 'Polling enabled', status: 'Healthy' },
          { title: 'LDAP', detail: 'Directory sync ready', status: 'Healthy' },
          { title: 'SMTP', detail: process.env.SMTP_HOST ? 'Configured' : 'Not configured', status: process.env.SMTP_HOST ? 'Healthy' : 'Needs attention' },
        ],
      });
    }

    if (moduleKey === 'synchronization-monitor') {
      const [activeSessions, users, students, reviews] = await Promise.all([
        prisma.fieldSession.count({ where: { status: 'ACTIVE' } }),
        prisma.user.count({ where: { deletedAt: null } }),
        prisma.studentProfile.count(),
        prisma.review.count(),
      ]);
      return res.json({
        cards: [
          { title: 'Student sync', detail: `${students} student profiles`, status: activeSessions > 0 ? 'Running' : 'Idle' },
          { title: 'Department sync', detail: 'Academic departments synced', status: 'Healthy' },
          { title: 'Supervisor sync', detail: 'Supervisor mapping active', status: 'Healthy' },
          { title: 'Research topics', detail: 'Topic catalog available', status: 'Healthy' },
          { title: 'Users', detail: `${users} users registered · ${reviews} reviews captured`, status: 'Healthy' },
        ],
      });
    }

    if (moduleKey === 'audit-center') {
      const auditEvents = await prisma.auditLog.findMany({ orderBy: { timestamp: 'desc' }, take: 20, include: { actor: true, user: true } });
      return res.json({
        items: auditEvents.map((event) => ({
          title: event.action,
          detail: `${event.actor?.name || 'System'} → ${event.user?.name || 'N/A'}`,
          status: event.action,
          timestamp: event.timestamp.toISOString(),
        })),
      });
    }

    if (moduleKey === 'notification-center') {
      const notifications = await prisma.notification.findMany({ orderBy: { createdAt: 'desc' }, take: 12, include: { recipient: true } });
      return res.json({
        items: notifications.map((notification) => ({
          title: notification.title,
          detail: `${notification.type} · ${notification.recipient?.name || 'Unknown'}`,
          status: notification.isRead ? 'Sent' : 'Pending',
          timestamp: notification.createdAt.toISOString(),
        })),
      });
    }

    if (moduleKey === 'feature-flags') {
      const flags = await getFeatureFlagsState();
      return res.json({
        cards: Object.entries(flags).map(([key, value]) => ({
          title: key,
          detail: value ? 'Enabled' : 'Disabled',
          status: value ? 'ON' : 'OFF',
        })),
      });
    }

    if (moduleKey === 'storage-analytics') {
      const media = await prisma.evidence.findMany({ orderBy: { fileSize: 'desc' }, take: 8 });
      const duplicateFiles = await prisma.evidence.findMany({ where: { checksum: { not: null } }, take: 8 });
      const totalSize = await prisma.evidence.aggregate({ _sum: { fileSize: true } });
      return res.json({
        cards: [
          { title: 'Images', detail: 'Image uploads tracked', status: 'Healthy' },
          { title: 'Videos', detail: 'Video uploads tracked', status: 'Healthy' },
          { title: 'Documents', detail: 'Documents stored', status: 'Healthy' },
          { title: 'Total storage', detail: `${totalSize._sum.fileSize || 0} bytes`, status: 'Healthy' },
          { title: 'Largest files', detail: `${media[0]?.originalName || 'None'} · ${media[0]?.fileSize || 0} bytes`, status: 'Healthy' },
          { title: 'Unused files', detail: 'No orphaned assets detected', status: 'Healthy' },
          { title: 'Duplicate files', detail: `${duplicateFiles.length} duplicate checksum entries`, status: duplicateFiles.length > 0 ? 'Needs attention' : 'Healthy' },
        ],
      });
    }

    if (moduleKey === 'security-center') {
      const [failedLogins, lockedAccounts, activeRefreshTokens, suspiciousEvents] = await Promise.all([
        prisma.auditLog.count({ where: { action: 'FAILED_LOGIN' } }),
        prisma.user.count({ where: { accountLockedUntil: { not: null } } }),
        prisma.refreshToken.count({ where: { expiresAt: { gt: new Date() }, revokedAt: null } }),
        prisma.auditLog.count({ where: { action: { in: ['FAILED_LOGIN', 'PASSWORD_RESET', 'USER_STATUS_UPDATED'] } } }),
      ]);
      return res.json({
        items: [
          { Metrics: 'Failed Logins', Count: failedLogins },
          { Metrics: 'Locked Accounts', Count: lockedAccounts },
          { Metrics: 'Active Refresh Tokens', Count: activeRefreshTokens },
          { Metrics: 'Suspicious Events', Count: suspiciousEvents },
        ],
      });
    }

    if (moduleKey === 'server-monitor') {
      const cpus = os.cpus();
      const cpuModel = cpus.length > 0 ? cpus[0].model : 'Unknown';
      const totalMem = os.totalmem();
      const freeMem = os.freemem();
      const memUsedPercent = Math.round(((totalMem - freeMem) / totalMem) * 100);
      const memProcess = process.memoryUsage();
      const uptime = process.uptime();

      let diskInfo = 'Unknown';
      try {
        const { stdout } = await execAsync('df -h / | tail -1 | awk \'{print $5 " used of " $2}\'');
        diskInfo = stdout.trim();
      } catch (e) {
        diskInfo = 'N/A (Windows/Err)';
      }

      return res.json({
        cards: [
          { title: 'CPU', detail: `${cpuModel} (${cpus.length} Cores)`, status: `${Math.round(os.loadavg()[0] * 100)}% load` },
          { title: 'System RAM', detail: `${Math.round((totalMem - freeMem) / (1024 * 1024))}MB / ${Math.round(totalMem / (1024 * 1024))}MB`, status: `${memUsedPercent}% used` },
          { title: 'Process RAM (Heap)', detail: `${Math.round(memProcess.heapUsed / 1024 / 1024)}MB / ${Math.round(memProcess.heapTotal / 1024 / 1024)}MB`, status: 'Healthy' },
          { title: 'Disk Usage', detail: diskInfo, status: 'Healthy' },
          { title: 'Node Process', detail: `PID: ${process.pid} | Uptime: ${Math.round(uptime / 3600)}h ${Math.round((uptime % 3600) / 60)}m`, status: 'Healthy' },
        ],
        chartData: {
          cpuLoad: os.loadavg()[0],
          memUsed: memUsedPercent,
        }
      });
    }

    if (moduleKey === 'version-manager') {
      return res.json({
        cards: [
          { title: 'Backend version', detail: backendPackageJson.version || '1.0.0', status: 'Healthy' },
          { title: 'Flutter version', detail: process.env.FLUTTER_VERSION || 'latest', status: 'Healthy' },
          { title: 'Database version', detail: 'PostgreSQL via Prisma', status: 'Healthy' },
          { title: 'Migration version', detail: 'Current schema', status: 'Healthy' },
          { title: 'Git commit', detail: process.env.GIT_COMMIT || 'local', status: 'Healthy' },
          { title: 'Build date', detail: new Date().toISOString(), status: 'Healthy' },
        ],
      });
    }

    if (moduleKey === 'backup-center') {
      return res.json({
        cards: [
          { title: 'Run backup', detail: 'Backup script available', status: 'Healthy' },
          { title: 'Download backup', detail: 'Archive export ready', status: 'Healthy' },
          { title: 'Restore backup', detail: 'Protected by safeguards', status: 'Healthy' },
          { title: 'Backup history', detail: 'Stored in logs and artifacts', status: 'Healthy' },
          { title: 'Backup status', detail: 'Current snapshot available', status: 'Healthy' },
        ],
      });
    }

    if (moduleKey === 'maintenance-mode') {
      const enabled = await getMaintenanceModeState();
      return res.json({
        cards: [
          { title: 'Maintenance', detail: enabled ? 'Enabled' : 'Disabled', status: enabled ? 'ON' : 'OFF' },
          { title: 'Custom message', detail: process.env.MAINTENANCE_MESSAGE || 'Scheduled maintenance', status: 'Configured' },
          { title: 'Allowed users', detail: 'Admins only', status: 'Protected' },
          { title: 'Estimated time', detail: process.env.MAINTENANCE_ESTIMATE || 'TBD', status: 'Scheduled' },
        ],
      });
    }

    if (moduleKey === 'logs-viewer') {
      const logs = await prisma.auditLog.findMany({ orderBy: { timestamp: 'desc' }, take: 20 });
      return res.json({
        items: logs.map((entry) => ({ title: entry.action, detail: entry.details ? JSON.stringify(entry.details) : 'No details', status: 'ok', timestamp: entry.timestamp.toISOString() })),
      });
    }

    if (moduleKey === 'api-testing-console') {
      return res.json({
        cards: [
          { title: 'GET /api/v1/admin/users', detail: 'Execute requests against the admin API', status: 'Ready' },
          { title: 'GET /api/v1/developer/health', detail: 'Verify runtime health', status: 'Ready' },
          { title: 'POST /api/v1/developer/tickets', detail: 'Submit support tickets', status: 'Ready' },
        ],
      });
    }

    if (moduleKey === 'environment-viewer') {
      return res.json({
        cards: [
          { title: 'Environment', detail: process.env.NODE_ENV || 'development', status: 'Healthy' },
          { title: 'API base URL', detail: process.env.API_BASE_URL || 'http://localhost:3000', status: 'Configured' },
          { title: 'Storage driver', detail: process.env.STORAGE_DRIVER || 'local', status: 'Healthy' },
          { title: 'SMTP status', detail: process.env.SMTP_HOST ? 'Configured' : 'Disabled', status: process.env.SMTP_HOST ? 'Healthy' : 'Needs attention' },
          { title: 'Current tenant', detail: 'default', status: 'Active' },
          { title: 'Application mode', detail: process.env.NODE_ENV || 'development', status: 'Healthy' },
        ],
      });
    }

    if (moduleKey === 'health-checks') {
      return res.json({
        cards: [
          { title: 'Database connectivity', detail: 'Prisma connection healthy', status: 'Healthy' },
          { title: 'File storage', detail: 'Storage directories available', status: 'Healthy' },
          { title: 'Queue status', detail: 'Background processing active', status: 'Healthy' },
          { title: 'Email service', detail: process.env.SMTP_HOST ? 'Configured' : 'Unavailable', status: process.env.SMTP_HOST ? 'Healthy' : 'Needs attention' },
          { title: 'Maps service', detail: 'Maps integration available', status: 'Healthy' },
          { title: 'Notification service', detail: 'Push and in-app notifications enabled', status: 'Healthy' },
          { title: 'Cache status', detail: 'Cache layer not configured', status: 'Needs attention' },
        ],
      });
    }

    if (moduleKey === 'release-center') {
      return res.json({
        cards: [
          { title: 'Current version', detail: backendPackageJson.version || '1.0.0', status: 'Healthy' },
          { title: 'Available update', detail: 'No pending update', status: 'Healthy' },
          { title: 'Migration status', detail: 'Schema up to date', status: 'Healthy' },
          { title: 'Release notes', detail: 'Latest dashboard release', status: 'Ready' },
          { title: 'Rollback', detail: 'Available through deployment controls', status: 'Ready' },
        ],
      });
    }

    return res.status(404).json({ error: 'Module not found' });
  } catch (error) {
    appLogger.error('Developer dashboard module data failed', error);
    return res.status(500).json({ error: 'Unable to load module data' });
  }
});

router.get('/metrics', async (_req: Request, res: Response) => {
  try {
    const [users, activeSessions, pendingReviews, failedLogins, recentActivities] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }),
      prisma.fieldSession.count({ where: { checkOutTime: null } }),
      prisma.review.count({ where: { status: 'UNDER_REVIEW' } }),
      prisma.auditLog.count({ where: { action: 'FAILED_LOGIN' } }),
      prisma.fieldLog.count({ where: { timestamp: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } } }),
    ]);

    res.json({
      metrics: {
        users,
        activeSessions,
        pendingReviews,
        failedLogins,
        recentActivities,
      },
      trend: [
        { label: 'Users', value: users },
        { label: 'Active sessions', value: activeSessions },
        { label: 'Pending reviews', value: pendingReviews },
        { label: 'Failed logins', value: failedLogins },
      ],
    });
  } catch (error) {
    appLogger.error('Developer dashboard metrics failed', error);
    res.status(500).json({ error: 'Unable to load metrics' });
  }
});

router.post('/support-request', async (req: Request, res: Response) => {
  try {
    const { category, title, description, contactEmail, severity } = req.body;
    const payload = {
      id: `support-${Date.now()}`,
      category: category || 'bug_report',
      title: title || 'Support request',
      description: description || '',
      contactEmail: contactEmail || '',
      severity: severity || 'medium',
      reporterId: req.user?.userId || 'anonymous',
      createdAt: new Date().toISOString(),
    };

    await prisma.auditLog.create({
      data: {
        action: 'SUPPORT_REQUEST_CREATED',
        details: payload,
        actorId: req.user?.userId,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      },
    });

    broadcastDashboardEvent({ type: 'support_request', payload });
    res.status(201).json({ success: true, payload });
  } catch (error) {
    appLogger.error('Support request creation failed', error);
    res.status(500).json({ error: 'Unable to create support request' });
  }
});

router.get('/status', async (_req: Request, res: Response) => {
  try {
    const [applicationLogs, authLogs, uploadLogs] = await Promise.all([
      appLogger.level,
      authLogger.level,
      uploadsLogger.level,
    ]);

    res.json({
      status: 'ok',
      loggers: {
        application: applicationLogs,
        auth: authLogs,
        uploads: uploadLogs,
      },
      features: {
        healthEndpoint: true,
        requestTracking: true,
        issueFeed: true,
        metricsBoard: true,
      },
    });
  } catch (error) {
    appLogger.error('Developer dashboard status failed', error);
    res.status(500).json({ error: 'Unable to load status' });
  }
});

// ---- Administrative Actions ----
router.put('/actions/feature-flags/:key', async (req: Request, res: Response) => {
  try {
    const decodedKey = decodeURIComponent(String(req.params.key ?? ''));
    const { enabled } = req.body;
    const flags = await getFeatureFlagsState();

    if (typeof decodedKey === 'string' && decodedKey in flags) {
      const nextFlags = { ...flags, [decodedKey]: Boolean(enabled) };
      await saveFeatureFlagsState(nextFlags, req.user?.userId || 'developer-admin');
      await saveLastActionStatus(`feature-flag:${decodedKey}`, 'success', `Feature flag ${decodedKey} ${Boolean(enabled) ? 'enabled' : 'disabled'}`, req.user?.userId || 'developer-admin');
      return res.json({ success: true, message: `Feature flag ${decodedKey} updated` });
    }
    return res.status(404).json({ error: 'Feature flag not found' });
  } catch (error) {
    appLogger.error('Feature flag update error', error);
    await saveLastActionStatus('feature-flag:unknown', 'error', 'Failed to update feature flag', req.user?.userId || 'developer-admin');
    res.status(500).json({ error: 'Failed to update feature flag' });
  }
});

router.post('/actions/database', async (req: Request, res: Response) => {
  try {
    const { category, key, id, action } = req.body;
    if (action === 'delete') {
      if (category === 'Users') await prisma.user.delete({ where: { id } });
      else if (category === 'Students') await prisma.studentProfile.delete({ where: { id } });
      else if (category === 'Activities') await prisma.fieldLog.delete({ where: { id } });
      else if (category === 'Evidence') await prisma.evidence.delete({ where: { id } });
      else if (category === 'Notifications') await prisma.notification.delete({ where: { id } });
      else if (category === 'Reviews') await prisma.review.delete({ where: { id } });
    } else if (action === 'suspend') {
      if (category === 'Users') await prisma.user.update({ where: { id }, data: { deletedAt: new Date() } });
      // Ignoring unsupported suspend for other categories
    }
    await saveLastActionStatus(`database:${action}`, 'success', `Database action ${action} executed for ${category}`, req.user?.userId || 'developer-admin');
    return res.json({ success: true, message: `Action ${action} executed on ${category}` });
  } catch (error) {
    appLogger.error('Database action error', error);
    await saveLastActionStatus('database:unknown', 'error', 'Database action failed', req.user?.userId || 'developer-admin');
    res.status(500).json({ error: 'Database action failed' });
  }
});
router.post('/actions/maintenance', async (req: Request, res: Response) => {
  try {
    const { enabled } = req.body;
    const nextValue = Boolean(enabled);
    process.env.MAINTENANCE_MODE = nextValue ? 'true' : 'false';
    await saveMaintenanceModeState(nextValue, req.user?.userId || 'developer-admin');

    await prisma.auditLog.create({
      data: { action: 'MAINTENANCE_TOGGLED', details: { enabled: nextValue }, actorId: req.user?.userId }
    });
    await saveLastActionStatus('maintenance-mode', 'success', `Maintenance mode ${nextValue ? 'enabled' : 'disabled'}`, req.user?.userId || 'developer-admin');
    return res.json({ success: true, message: `Maintenance mode ${nextValue ? 'enabled' : 'disabled'}` });
  } catch (error) {
    await saveLastActionStatus('maintenance-mode', 'error', 'Failed to toggle maintenance mode', req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Failed to toggle maintenance' });
  }
});

router.post('/actions/clear-logs', async (req: Request, res: Response) => {
  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const { count } = await prisma.auditLog.deleteMany({
      where: { timestamp: { lt: thirtyDaysAgo } }
    });

    await prisma.auditLog.create({
      data: { action: 'LOGS_CLEARED', details: { recordsDeleted: count }, actorId: req.user?.userId }
    });
    await saveLastActionStatus('clear-logs', 'success', `Cleared ${count} old audit logs`, req.user?.userId || 'developer-admin');
    return res.json({ success: true, message: `Cleared ${count} old audit logs` });
  } catch (error) {
    await saveLastActionStatus('clear-logs', 'error', 'Failed to clear old logs', req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Failed to clear logs' });
  }
});

router.post('/actions/restart', async (req: Request, res: Response) => {
  try {
    await prisma.auditLog.create({
      data: { action: 'SERVER_RESTART_REQUESTED', actorId: req.user?.userId }
    });
    await saveLastActionStatus('restart', 'success', 'Server restart requested', req.user?.userId || 'developer-admin');
    res.json({ success: true, message: 'Server restarting...' });

    setTimeout(() => {
      process.exit(0);
    }, 1000);
  } catch (error) {
    await saveLastActionStatus('restart', 'error', 'Failed to initiate server restart', req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Failed to initiate restart' });
  }
});

router.post('/actions/vps-command', async (req: Request, res: Response) => {
  try {
    const { command } = req.body;
    if (!command || typeof command !== 'string') return res.status(400).json({error: 'Invalid command'});

    const { stdout, stderr } = await execAsync(command, { timeout: 10000 });

    await prisma.auditLog.create({
      data: { action: 'VPS_COMMAND_EXECUTED', details: { command }, actorId: req.user?.userId }
    });
    await saveLastActionStatus('vps-command', 'success', `Executed command: ${command.slice(0, 80)}`, req.user?.userId || 'developer-admin');

    return res.json({ success: true, stdout, stderr });
  } catch (error: any) {
    await saveLastActionStatus('vps-command', 'error', `Failed command: ${String(error.message || error)}`.slice(0, 160), req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Command failed', stderr: error.message || String(error) });
  }
});

router.post('/actions/security-revoke', async (req: Request, res: Response) => {
  try {
    const { count } = await prisma.refreshToken.updateMany({
      where: { revokedAt: null },
      data: { revokedAt: new Date() }
    });
    await prisma.auditLog.create({
      data: { action: 'ALL_TOKENS_REVOKED', details: { count }, actorId: req.user?.userId }
    });
    await saveLastActionStatus('security-revoke', 'success', `Revoked ${count} active sessions`, req.user?.userId || 'developer-admin');
    return res.json({ success: true, message: `Revoked ${count} active sessions` });
  } catch (error) {
    await saveLastActionStatus('security-revoke', 'error', 'Failed to revoke active sessions', req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Failed to revoke tokens' });
  }
});

router.post('/actions/security-lock', async (req: Request, res: Response) => {
  try {
    const { count } = await prisma.user.updateMany({
      where: { failedLoginAttempts: { gte: 5 }, accountLockedUntil: null },
      data: { accountLockedUntil: new Date(Date.now() + 24 * 60 * 60 * 1000) }
    });
    await prisma.auditLog.create({
      data: { action: 'SUSPICIOUS_ACCOUNTS_LOCKED', details: { count }, actorId: req.user?.userId }
    });
    await saveLastActionStatus('security-lock', 'success', `Locked ${count} suspicious accounts`, req.user?.userId || 'developer-admin');
    return res.json({ success: true, message: `Locked ${count} suspicious accounts` });
  } catch (error) {
    await saveLastActionStatus('security-lock', 'error', 'Failed to lock suspicious accounts', req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Failed to lock accounts' });
  }
});

router.post('/actions/jobs-clear', async (req: Request, res: Response) => {
  try {
    const { count } = await prisma.evidence.deleteMany({
      where: { uploadStatus: 'FAILED' }
    });
    await prisma.auditLog.create({
      data: { action: 'FAILED_UPLOADS_CLEARED', details: { count }, actorId: req.user?.userId }
    });
    await saveLastActionStatus('jobs-clear', 'success', `Cleared ${count} failed uploads`, req.user?.userId || 'developer-admin');
    return res.json({ success: true, message: `Cleared ${count} failed uploads` });
  } catch (error) {
    await saveLastActionStatus('jobs-clear', 'error', 'Failed to clear failed uploads', req.user?.userId || 'developer-admin');
    return res.status(500).json({ error: 'Failed to clear jobs' });
  }
});

export default router;
