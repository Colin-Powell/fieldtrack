import cron from 'node-cron';
import { prisma } from '../db.js';
import { emailService } from '../auth/email.service.js';
import { NotificationService } from '../notifications/notification.service.js';

const notificationService = new NotificationService();

const INACTIVE_SESSION_THRESHOLD_MINUTES = 30;
const OVERDUE_SESSION_THRESHOLD_HOURS = 12;
const STUDENT_ACTIVITY_REMINDER_HOURS = 24;
const STUDENT_SUBMISSION_REMINDER_HOURS = 12;
const STUDENT_CHECKIN_REMINDER_MINUTES = 30;

function formatRelativeTime(date: Date) {
  const minutes = Math.max(1, Math.round((Date.now() - date.getTime()) / 60000));
  return `${minutes} minute${minutes == 1 ? '' : 's'}`;
}

async function sendSupervisorNotification(supervisorId: string, title: string, message: string, email: string | null, preferences: any | null) {
  await notificationService.sendNotification({
    recipientId: supervisorId,
    title,
    message,
    type: 'SYSTEM_ALERT',
    priority: 1,
  });

  if (preferences?.chanEmail ?? true) {
    try {
      await emailService.sendEmail(
        email ?? '',
        title,
        `<p>${message}</p>`,
        message,
      );
    } catch (error) {
      console.error('Failed to send supervisor alert email:', error);
    }
  }
}

async function sendStudentNotification(studentId: string, title: string, message: string, preferences: any | null) {
  if (preferences?.chanInApp === false) {
    return;
  }

  await notificationService.sendNotification({
    recipientId: studentId,
    title,
    message,
    type: 'SYSTEM_ALERT',
    priority: 1,
  });
}

async function hasRecentStudentReminder(studentId: string, title: string, lookbackHours: number) {
  const since = new Date(Date.now() - lookbackHours * 60 * 60 * 1000);
  return prisma.notification.findFirst({
    where: {
      recipientId: studentId,
      title,
      type: 'SYSTEM_ALERT',
      createdAt: { gte: since },
    },
  });
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

    if (!supervisor || !supervisor.email) continue;
    if (supervisorPrefs?.notifCheckInOut === false) continue;

    const lastPing = session.locationPings?.[0]?.timestamp;
    if (!lastPing || lastPing > cutoff) continue;

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

    if (!supervisor || !supervisor.email) continue;
    if (supervisorPrefs?.notifCheckInOut === false) continue;

    const title = 'Overdue field session';
    const message = `Student ${student.name} has been checked in for over ${OVERDUE_SESSION_THRESHOLD_HOURS} hours without checking out.`;

    await sendSupervisorNotification(supervisor.id, title, message, supervisor.email, supervisorPrefs);
  }
}

export async function checkStudentActivityReminders() {
  const cutoff = new Date(Date.now() - STUDENT_ACTIVITY_REMINDER_HOURS * 60 * 60 * 1000);

  const activities = await prisma.fieldLog.findMany({
    where: {
      status: 'DRAFT',
      timestamp: { lt: cutoff },
    },
    include: {
      user: {
        include: {
          preferences: true,
        },
      },
    },
  });

  for (const activity of activities) {
    const student = activity.user;
    const studentPrefs = student.preferences;

    if (studentPrefs?.notifNewActivity === false) continue;

    const title = 'Activity reminder';
    const message = `Please complete your activity "${activity.title}" before it becomes overdue.`;

    const recent = await hasRecentStudentReminder(student.id, title, 6);
    if (recent) continue;

    await sendStudentNotification(student.id, title, message, studentPrefs);
  }
}

export async function checkStudentCheckInReminders() {
  const cutoff = new Date(Date.now() - STUDENT_CHECKIN_REMINDER_MINUTES * 60 * 1000);

  const sessions = await prisma.fieldSession.findMany({
    where: {
      checkOutTime: null,
    },
    include: {
      user: {
        include: {
          preferences: true,
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
    const lastPing = session.locationPings?.[0]?.timestamp;
    const studentPrefs = student.preferences;

    if (studentPrefs?.notifCheckInOut === false) continue;
    if (!lastPing || lastPing >= cutoff) continue;

    const title = 'Check-in reminder';
    const message = 'Please send a fresh location ping to confirm your field session is still active.';

    const recent = await hasRecentStudentReminder(student.id, title, 2);
    if (recent) continue;

    await sendStudentNotification(student.id, title, message, studentPrefs);
  }
}

export async function checkStudentSubmissionReminders() {
  const cutoff = new Date(Date.now() - STUDENT_SUBMISSION_REMINDER_HOURS * 60 * 60 * 1000);

  const submissions = await prisma.fieldLog.findMany({
    where: {
      status: {
        in: ['SUBMITTED', 'UNDER_REVIEW', 'RESUBMITTED'],
      },
      timestamp: { lt: cutoff },
    },
    include: {
      user: {
        include: {
          preferences: true,
        },
      },
    },
  });

  for (const submission of submissions) {
    const student = submission.user;
    const studentPrefs = student.preferences;

    if (studentPrefs?.notifReview === false) continue;

    const title = 'Submission reminder';
    const message = `Your activity report "${submission.title}" is still waiting for a review update. Please check your dashboard for the latest status.`;

    const recent = await hasRecentStudentReminder(student.id, title, 6);
    if (recent) continue;

    await sendStudentNotification(student.id, title, message, studentPrefs);
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
    if (!profile) continue;
    const prefs = supervisor.preferences;
    if (prefs?.notifAnnouncements === false) continue;

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
      } catch (error) {
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
    } catch (error) {
      console.error('[scheduler] Inactive session alert job failed:', error);
    }
  });

  cron.schedule('*/30 * * * *', async () => {
    console.log('[scheduler] Running overdue session alert job.');
    try {
      await checkOverdueFieldSessions();
    } catch (error) {
      console.error('[scheduler] Overdue session alert job failed:', error);
    }
  });

  cron.schedule('*/15 * * * *', async () => {
    console.log('[scheduler] Running student check-in reminder job.');
    try {
      await checkStudentCheckInReminders();
    } catch (error) {
      console.error('[scheduler] Student check-in reminder job failed:', error);
    }
  });

  cron.schedule('0 */6 * * *', async () => {
    console.log('[scheduler] Running student activity reminder job.');
    try {
      await checkStudentActivityReminders();
    } catch (error) {
      console.error('[scheduler] Student activity reminder job failed:', error);
    }
  });

  cron.schedule('0 */6 * * *', async () => {
    console.log('[scheduler] Running student submission reminder job.');
    try {
      await checkStudentSubmissionReminders();
    } catch (error) {
      console.error('[scheduler] Student submission reminder job failed:', error);
    }
  });

  cron.schedule('0 7 * * *', async () => {
    console.log('[scheduler] Running daily supervisor summary job.');
    try {
      await sendDailySupervisorSummaries();
    } catch (error) {
      console.error('[scheduler] Daily summary job failed:', error);
    }
  });
}
