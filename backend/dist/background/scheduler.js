import cron from 'node-cron';
import { prisma } from '../db.js';
import { emailService } from '../auth/email.service.js';
import { NotificationService } from '../notifications/notification.service.js';
const notificationService = new NotificationService();
const INACTIVE_SESSION_THRESHOLD_MINUTES = 30;
const OVERDUE_SESSION_THRESHOLD_HOURS = 12;
function formatRelativeTime(date) {
    const minutes = Math.max(1, Math.round((Date.now() - date.getTime()) / 60000));
    return `${minutes} minute${minutes == 1 ? '' : 's'}`;
}
async function sendSupervisorNotification(supervisorId, title, message, email, preferences) {
    await notificationService.sendNotification({
        recipientId: supervisorId,
        title,
        message,
        type: 'SYSTEM_ALERT',
        priority: 1,
    });
    if (preferences?.chanEmail ?? true) {
        try {
            await emailService.sendEmail(email ?? '', title, `<p>${message}</p>`, message);
        }
        catch (error) {
            console.error('Failed to send supervisor alert email:', error);
        }
    }
}
export async function checkInactiveStudentSessions() {
    const cutoff = new Date(Date.now() - INACTIVE_SESSION_THRESHOLD_MINUTES * 60 * 1000);
    const sessions = await prisma.fieldSession.findMany({
        where: {
            checkOutTime: null,
            locationPings: {
                some: {
                    timestamp: { lt: cutoff },
                },
            },
        },
        include: {
            user: {
                include: {
                    studentProfile: {
                        include: {
                            supervisor: {
                                include: {
                                    user: {
                                        include: { preferences: true },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            locationPings: {
                orderBy: { timestamp: 'desc' },
                take: 1,
            },
        },
    });
    for (const session of sessions) {
        const student = session.user;
        const supervisor = student.studentProfile?.supervisor?.user;
        const supervisorPrefs = supervisor?.preferences;
        if (!supervisor || !supervisor.email)
            continue;
        if (supervisorPrefs?.notifCheckInOut === false)
            continue;
        const lastPing = session.locationPings?.[0]?.timestamp;
        if (!lastPing || lastPing > cutoff)
            continue;
        const timeAgo = formatRelativeTime(lastPing);
        const title = 'Inactive student update';
        const message = `Student ${student.name} has not reported a field location for ${timeAgo}. Please review their status.`;
        await sendSupervisorNotification(supervisor.id, title, message, supervisor.email, supervisorPrefs);
    }
}
export async function checkOverdueFieldSessions() {
    const cutoff = new Date(Date.now() - OVERDUE_SESSION_THRESHOLD_HOURS * 60 * 60 * 1000);
    const overdueSessions = await prisma.fieldSession.findMany({
        where: {
            checkOutTime: null,
            checkInTime: { lt: cutoff },
        },
        include: {
            user: {
                include: {
                    studentProfile: {
                        include: {
                            supervisor: {
                                include: {
                                    user: {
                                        include: { preferences: true },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    });
    for (const session of overdueSessions) {
        const student = session.user;
        const supervisor = student.studentProfile?.supervisor?.user;
        const supervisorPrefs = supervisor?.preferences;
        if (!supervisor || !supervisor.email)
            continue;
        if (supervisorPrefs?.notifCheckInOut === false)
            continue;
        const title = 'Overdue field session';
        const message = `Student ${student.name} has been checked in for over ${OVERDUE_SESSION_THRESHOLD_HOURS} hours without checking out.`;
        await sendSupervisorNotification(supervisor.id, title, message, supervisor.email, supervisorPrefs);
    }
}
export async function sendDailySupervisorSummaries() {
    const supervisors = await prisma.user.findMany({
        where: { role: 'SUPERVISOR' },
        include: {
            preferences: true,
            supervisorProfile: true,
        },
    });
    for (const supervisor of supervisors) {
        const profile = supervisor.supervisorProfile;
        if (!profile)
            continue;
        const prefs = supervisor.preferences;
        if (prefs?.notifAnnouncements === false)
            continue;
        const activeStudentsCount = await prisma.user.count({
            where: {
                role: 'STUDENT',
                studentProfile: { supervisorId: profile.id },
                fieldSessions: { some: { checkOutTime: null } },
            },
        });
        const overdueCount = await prisma.fieldSession.count({
            where: {
                checkOutTime: null,
                checkInTime: { lt: new Date(Date.now() - OVERDUE_SESSION_THRESHOLD_HOURS * 60 * 60 * 1000) },
                user: { studentProfile: { supervisorId: profile.id } },
            },
        });
        const unreadAlertsCount = await prisma.notification.count({
            where: {
                recipientId: supervisor.id,
                isRead: false,
            },
        });
        const title = 'Daily FieldTrack summary';
        const message = `Good morning! You have ${activeStudentsCount} active student(s) in the field, ${overdueCount} overdue session(s), and ${unreadAlertsCount} unread notification(s).`;
        if (prefs?.chanInApp ?? true) {
            await notificationService.sendNotification({
                recipientId: supervisor.id,
                title,
                message,
                type: 'SYSTEM_ALERT',
                priority: 0,
            });
        }
        if (prefs?.chanEmail ?? true) {
            try {
                await emailService.sendEmail(supervisor.email, title, `<p>${message}</p>`, message);
            }
            catch (error) {
                console.error('Failed to send daily summary email:', error);
            }
        }
    }
}
export function startScheduler() {
    console.log('[scheduler] Starting background scheduler.');
    cron.schedule('*/15 * * * *', async () => {
        console.log('[scheduler] Running inactive session alert job.');
        try {
            await checkInactiveStudentSessions();
        }
        catch (error) {
            console.error('[scheduler] Inactive session alert job failed:', error);
        }
    });
    cron.schedule('*/30 * * * *', async () => {
        console.log('[scheduler] Running overdue session alert job.');
        try {
            await checkOverdueFieldSessions();
        }
        catch (error) {
            console.error('[scheduler] Overdue session alert job failed:', error);
        }
    });
    cron.schedule('0 7 * * *', async () => {
        console.log('[scheduler] Running daily supervisor summary job.');
        try {
            await sendDailySupervisorSummaries();
        }
        catch (error) {
            console.error('[scheduler] Daily summary job failed:', error);
        }
    });
}
