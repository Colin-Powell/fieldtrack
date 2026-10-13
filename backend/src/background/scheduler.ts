import cron from 'node-cron';
import { checkMissingLocations, checkOverdueSessions } from './jobs/session.jobs.js';
import { checkDraftActivities, checkReadyToSubmit, checkPendingSubmissions, checkMissingEvidence } from './jobs/activity.jobs.js';
import { checkPendingReviews, checkRevisionOverdue } from './jobs/review.jobs.js';
import { sendSupervisorDailyBriefing, sendStudentDailyBriefing, sendAdminDailyBriefing } from './jobs/digest.jobs.js';

export function startScheduler() {
  console.log('[Scheduler] Initializing background jobs with EAT timezone...');

  const timezone = 'Africa/Nairobi';

  // --- Frequent Escalation Checks (Run every 15 minutes) ---
  cron.schedule('*/15 * * * *', async () => {
    console.log('[Scheduler] Running 15m escalation checks...');
    await checkMissingLocations();
    await checkOverdueSessions();
    await checkReadyToSubmit();
  }, { timezone });

  // --- Hourly Checks ---
  cron.schedule('0 * * * *', async () => {
    console.log('[Scheduler] Running hourly workflow checks...');
    await checkDraftActivities();
    await checkPendingSubmissions();
    await checkMissingEvidence();
    await checkPendingReviews();
    await checkRevisionOverdue();
  }, { timezone });

  // --- Daily Digests (Idempotent) ---
  // Student Digest at 07:00 EAT
  cron.schedule('0 7 * * *', async () => {
    console.log('[Scheduler] Generating Student Daily Briefings...');
    await sendStudentDailyBriefing();
  }, { timezone });

  // Supervisor Digest at 08:00 EAT
  cron.schedule('0 8 * * *', async () => {
    console.log('[Scheduler] Generating Supervisor Daily Briefings...');
    await sendSupervisorDailyBriefing();
  }, { timezone });

  // Admin/System Digest at 08:30 EAT
  cron.schedule('30 8 * * *', async () => {
    console.log('[Scheduler] Generating Admin Daily Briefings...');
    await sendAdminDailyBriefing();
  }, { timezone });
}

