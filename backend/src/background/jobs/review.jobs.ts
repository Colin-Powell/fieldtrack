import { prisma } from '../../db.js';
import { NotificationService } from '../../notifications/notification.service.js';

const notificationService = new NotificationService();

async function hasSentNotification(recipientId: string, title: string, sinceHours: number) {
  const since = new Date(Date.now() - sinceHours * 60 * 60 * 1000);
  const existing = await prisma.notification.findFirst({
    where: {
      recipientId,
      title,
      createdAt: { gte: since }
    }
  });
  return !!existing;
}

export async function checkPendingReviews() {
  const now = new Date();

  const pendingActivities = await prisma.fieldLog.findMany({
    where: { status: { in: ['SUBMITTED', 'RESUBMITTED'] } },
    include: {
      user: {
        include: {
          studentProfile: {
            include: {
              supervisor: {
                include: { user: true }
              }
            }
          }
        }
      }
    }
  });

  const supervisorBacklog = new Map<string, { supervisorId: string, activities12h: number, activities24h: number }>();

  for (const activity of pendingActivities) {
    const supervisor = activity.user.studentProfile?.supervisor?.user;
    if (!supervisor) continue;

    const hoursPending = (now.getTime() - activity.timestamp.getTime()) / (1000 * 60 * 60);
    
    if (!supervisorBacklog.has(supervisor.id)) {
      supervisorBacklog.set(supervisor.id, { supervisorId: supervisor.id, activities12h: 0, activities24h: 0 });
    }
    
    const stats = supervisorBacklog.get(supervisor.id)!;
    if (hoursPending >= 24) {
      stats.activities24h++;
    } else if (hoursPending >= 12) {
      stats.activities12h++;
    }
  }

  for (const [supervisorId, stats] of supervisorBacklog.entries()) {
    if (stats.activities24h > 0) {
      const title = 'Critical: Pending reviews 24h';
      if (!(await hasSentNotification(supervisorId, title, 24))) {
        await notificationService.sendNotification({ recipientId: supervisorId, title, message: `You have ${stats.activities24h} activities awaiting review for over 24 hours.`, type: 'SYSTEM_ALERT', priority: 2 });
      }
    } else if (stats.activities12h > 0) {
      const title = 'Warning: Pending reviews 12h';
      if (!(await hasSentNotification(supervisorId, title, 12))) {
        await notificationService.sendNotification({ recipientId: supervisorId, title, message: `You have ${stats.activities12h} activities awaiting review for over 12 hours.`, type: 'SYSTEM_ALERT', priority: 1 });
      }
    }
  }
}

export async function checkRevisionOverdue() {
  const now = new Date();

  const activities = await prisma.fieldLog.findMany({
    where: { status: 'REVISION_REQUESTED' },
    include: { user: true }
  });

  for (const activity of activities) {
    const hoursSinceRevision = (now.getTime() - activity.timestamp.getTime()) / (1000 * 60 * 60);

    if (hoursSinceRevision >= 24) {
      const title = 'Revision Overdue';
      if (!(await hasSentNotification(activity.user.id, title, 24))) {
        await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `Your activity "${activity.title}" requires revision. Please update it.`, type: 'SYSTEM_ALERT', priority: 1 });
      }
    }
  }
}
