import { prisma } from '../../db.js';
import { NotificationService } from '../../notifications/notification.service.js';
const notificationService = new NotificationService();
async function hasSentNotification(recipientId, entityId, title, sinceHours) {
    const since = new Date(Date.now() - sinceHours * 60 * 60 * 1000);
    const existing = await prisma.notification.findFirst({
        where: {
            recipientId,
            title,
            createdAt: { gte: since }
            // Assuming entityId isn't on Notification, if it is, we'd use it.
        }
    });
    return !!existing;
}
export async function checkMissingLocations() {
    const now = new Date();
    const sessions = await prisma.fieldSession.findMany({
        where: { checkOutTime: null },
        include: {
            user: {
                include: {
                    preferences: true,
                    studentProfile: { include: { supervisor: { include: { user: { include: { preferences: true } } } } } }
                }
            },
            locationPings: { orderBy: { timestamp: 'desc' }, take: 1 }
        }
    });
    for (const session of sessions) {
        const student = session.user;
        const supervisor = student.studentProfile?.supervisor?.user;
        let lastPing = session.locationPings?.[0]?.timestamp;
        if (!lastPing)
            lastPing = session.checkInTime;
        if (!lastPing)
            continue;
        const hoursSincePing = (now.getTime() - lastPing.getTime()) / (1000 * 60 * 60);
        if (hoursSincePing >= 24) {
            // 24h critical
            const title = 'Critical: Location missing 24h';
            if (supervisor && !(await hasSentNotification(supervisor.id, session.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: supervisor.id, title, message: `Student ${student.name} missing location for 24 hours.`, type: 'SYSTEM_ALERT', priority: 2 });
            }
        }
        else if (hoursSincePing >= 6) {
            // 6h escalation
            const title = 'Escalation: Location missing 6h';
            if (supervisor && !(await hasSentNotification(supervisor.id, session.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: supervisor.id, title, message: `Student ${student.name} missing location for 6 hours.`, type: 'SYSTEM_ALERT', priority: 2 });
            }
        }
        else if (hoursSincePing >= 2) {
            // 2h supervisor
            const title = 'Warning: Location missing 2h';
            if (supervisor && !(await hasSentNotification(supervisor.id, session.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: supervisor.id, title, message: `Student ${student.name} missing location for 2 hours.`, type: 'SYSTEM_ALERT', priority: 1 });
            }
        }
        else if (hoursSincePing >= 0.5) {
            // 30m soft warning
            const title = 'Location ping needed';
            if (!(await hasSentNotification(student.id, session.id, title, 2))) {
                await notificationService.sendNotification({ recipientId: student.id, title, message: `Please ensure your location is updating.`, type: 'SYSTEM_ALERT', priority: 0 });
            }
        }
    }
}
export async function checkOverdueSessions() {
    const now = new Date();
    const sessions = await prisma.fieldSession.findMany({
        where: { checkOutTime: null },
        include: {
            user: {
                include: {
                    studentProfile: { include: { supervisor: { include: { user: true } } } }
                }
            }
        }
    });
    for (const session of sessions) {
        if (!session.checkInTime)
            continue;
        const student = session.user;
        const supervisor = student.studentProfile?.supervisor?.user;
        const hoursSinceCheckIn = (now.getTime() - session.checkInTime.getTime()) / (1000 * 60 * 60);
        if (hoursSinceCheckIn >= 24) {
            // 24h crit
            const title = 'Critical: Session overdue 24h';
            if (supervisor && !(await hasSentNotification(supervisor.id, session.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: supervisor.id, title, message: `Student ${student.name} session overdue by 24h.`, type: 'SYSTEM_ALERT', priority: 2 });
            }
        }
        else if (hoursSinceCheckIn >= 12) {
            // 12h sup
            const title = 'Warning: Session overdue 12h';
            if (supervisor && !(await hasSentNotification(supervisor.id, session.id, title, 24))) {
                await notificationService.sendNotification({ recipientId: supervisor.id, title, message: `Student ${student.name} session overdue by 12h.`, type: 'SYSTEM_ALERT', priority: 1 });
            }
        }
        else if (hoursSinceCheckIn >= 8) {
            // 8h stud
            const title = 'Reminder: Checkout needed';
            if (!(await hasSentNotification(student.id, session.id, title, 12))) {
                await notificationService.sendNotification({ recipientId: student.id, title, message: `Your session has been active for 8 hours. Don't forget to check out.`, type: 'SYSTEM_ALERT', priority: 0 });
            }
        }
    }
}
