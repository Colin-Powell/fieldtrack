import { prisma } from '../../db.js';
import { NotificationService } from '../../notifications/notification.service.js';
import { emailService } from '../../auth/email.service.js';

const notificationService = new NotificationService();

function getTodayString() {
  const now = new Date();
  return `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
}

async function hasSentDigest(recipientId: string, type: string) {
  const dateStr = getTodayString();
  const title = `${type} - ${dateStr}`;
  const existing = await prisma.notification.findFirst({
    where: {
      recipientId,
      title,
    }
  });
  return !!existing;
}

async function markDigestSent(recipientId: string, type: string, message: string) {
  const dateStr = getTodayString();
  const title = `${type} - ${dateStr}`;
  await notificationService.sendNotification({
    recipientId,
    title,
    message,
    type: 'SYSTEM_ALERT',
    priority: 0,
  });
}

export async function sendSupervisorDailyBriefing() {
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

    if (await hasSentDigest(supervisor.id, 'Daily Supervisor Digest')) continue;

    const activeStudentsCount = await prisma.user.count({
      where: {
        role: 'STUDENT',
        studentProfile: { supervisorId: profile.id },
        fieldSessions: { some: { checkOutTime: null } },
      },
    });

    const pendingReviews = await prisma.fieldLog.count({
      where: {
        status: { in: ['SUBMITTED', 'RESUBMITTED'] },
        user: { studentProfile: { supervisorId: profile.id } }
      }
    });

    const message = `Good morning! You have ${activeStudentsCount} active student(s) in the field, and ${pendingReviews} activities awaiting review.`;

    await markDigestSent(supervisor.id, 'Daily Supervisor Digest', message);

    if (supervisor.preferences?.chanEmail ?? true) {
      try {
        await emailService.sendEmail(supervisor.email, 'Daily FieldTrack summary', `<p>${message}</p>`, message);
      } catch (error) {
        console.error('Failed to send daily summary email:', error);
      }
    }
  }
}

export async function sendStudentDailyBriefing() {
  const students = await prisma.user.findMany({
    where: { role: 'STUDENT' },
    include: { preferences: true },
  });

  for (const student of students) {
    if (await hasSentDigest(student.id, 'Daily Student Digest')) continue;

    const pendingDrafts = await prisma.fieldLog.count({
      where: { status: 'DRAFT', userId: student.id }
    });

    const revisionsRequired = await prisma.fieldLog.count({
      where: { status: 'REVISION_REQUESTED', userId: student.id }
    });

    const message = `Good morning! You have ${pendingDrafts} draft activities and ${revisionsRequired} activities requiring revision.`;

    await markDigestSent(student.id, 'Daily Student Digest', message);

    if (student.preferences?.chanEmail ?? true) {
      try {
        await emailService.sendEmail(student.email, 'Daily FieldTrack summary', `<p>${message}</p>`, message);
      } catch (error) {
        console.error('Failed to send daily summary email:', error);
      }
    }
  }
}

export async function sendAdminDailyBriefing() {
  const admins = await prisma.user.findMany({
    where: { role: 'ADMIN' },
    include: { preferences: true },
  });

  for (const admin of admins) {
    if (await hasSentDigest(admin.id, 'Daily Admin Digest')) continue;

    const totalActiveSessions = await prisma.fieldSession.count({
      where: { checkOutTime: null }
    });

    const message = `Good morning Admin! There are currently ${totalActiveSessions} active sessions system-wide.`;

    await markDigestSent(admin.id, 'Daily Admin Digest', message);

    if (admin.preferences?.chanEmail ?? true) {
      try {
        await emailService.sendEmail(admin.email, 'Daily FieldTrack summary', `<p>${message}</p>`, message);
      } catch (error) {
        console.error('Failed to send daily summary email:', error);
      }
    }
  }
}
