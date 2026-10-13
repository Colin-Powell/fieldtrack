import { prisma } from '../../db.js';
import { NotificationService } from '../../notifications/notification.service.js';
import { ReadinessService } from '../../activities/readiness.service.js';
const notificationService = new NotificationService();
async function hasSentNotification(recipientId, title, sinceHours) {
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
export async function checkDraftActivities() {
    const now = new Date();
    const activities = await prisma.fieldLog.findMany({
        where: { status: 'DRAFT' },
        include: { user: true }
    });
    for (const activity of activities) {
        const hoursSinceCreation = (now.getTime() - activity.timestamp.getTime()) / (1000 * 60 * 60);
        if (hoursSinceCreation >= 48) {
            const title = 'Escalation: Draft activity 48h';
            if (!(await hasSentNotification(activity.user.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `Your draft "${activity.title}" is pending for 48 hours. Please complete and submit it.`, type: 'SYSTEM_ALERT', priority: 2 });
            }
        }
        else if (hoursSinceCreation >= 24) {
            const title = 'Warning: Draft activity 24h';
            if (!(await hasSentNotification(activity.user.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `Your draft "${activity.title}" has been unsubmitted for 24 hours.`, type: 'SYSTEM_ALERT', priority: 1 });
            }
        }
        else if (hoursSinceCreation >= 6) {
            const title = 'Reminder: Draft activity';
            if (!(await hasSentNotification(activity.user.id, title, 12))) {
                await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `You have an unfinished draft "${activity.title}".`, type: 'SYSTEM_ALERT', priority: 0 });
            }
        }
    }
}
export async function checkReadyToSubmit() {
    const activities = await prisma.fieldLog.findMany({
        where: { status: 'DRAFT' },
        include: { user: true, evidence: true }
    });
    for (const activity of activities) {
        const readiness = ReadinessService.evaluate(activity);
        if (readiness.isReady) {
            const title = 'Ready to submit';
            if (!(await hasSentNotification(activity.user.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `Your activity "${activity.title}" is ready to be submitted.`, type: 'SYSTEM_ALERT', priority: 0 });
            }
        }
    }
}
export async function checkMissingEvidence() {
    const now = new Date();
    const activities = await prisma.fieldLog.findMany({
        where: { status: 'DRAFT' },
        include: { user: true, evidence: true }
    });
    for (const activity of activities) {
        const hoursSinceCreation = (now.getTime() - activity.timestamp.getTime()) / (1000 * 60 * 60);
        if (hoursSinceCreation >= 12 && activity.evidence.length === 0) {
            const title = 'Missing evidence';
            if (!(await hasSentNotification(activity.user.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `Your activity "${activity.title}" is missing evidence after 12 hours.`, type: 'SYSTEM_ALERT', priority: 1 });
            }
        }
    }
}
export async function checkPendingSubmissions() {
    const now = new Date();
    const activities = await prisma.fieldLog.findMany({
        where: { status: 'DRAFT' },
        include: { user: true }
    });
    for (const activity of activities) {
        const hoursSinceCreation = (now.getTime() - activity.timestamp.getTime()) / (1000 * 60 * 60);
        if (hoursSinceCreation >= 12) {
            const title = 'Pending submission reminder';
            if (!(await hasSentNotification(activity.user.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: activity.user.id, title, message: `Please submit your activity "${activity.title}".`, type: 'SYSTEM_ALERT', priority: 0 });
            }
        }
    }
}
