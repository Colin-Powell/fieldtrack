import { Worker } from 'bullmq';
import { redis } from './utils/redis.js';
import { appLogger } from './utils/logger.js';
import { processBulkNotifications } from './notifications/notification.service.js';
import { processCsvImport } from './admins/admins.csv.js';
import { initFirebaseAdmin } from './firebase_admin.js';

// Define the connection to Redis
const connection = redis;

await initFirebaseAdmin();

appLogger.info('Starting Background Workers...');

// --- Workers ----------------------------------------------------------------

export const notificationWorker = new Worker('notificationQueue', async job => {
  if (job.name === 'bulkNotification') {
    await processBulkNotifications(job.data);
  }
}, { connection, concurrency: 20 });

export const csvImportWorker = new Worker('csvImportQueue', async job => {
  if (job.name === 'importUsers') {
    await processCsvImport(job.data);
  }
}, { connection, concurrency: 2 });

// Media processing is CPU/IO heavy � limit concurrency tightly
export const mediaWorker = new Worker('mediaQueue', async job => {
  if (job.name === 'processUpload') {
    const { processMediaUpload } = await import('./media/storage.service.js');
    await processMediaUpload(job.data);
  }
}, { connection, concurrency: 5 });

// Audit logging is lightweight DB writes � allow high throughput
export const auditWorker = new Worker('auditQueue', async job => {
  if (job.name === 'logAudit') {
    const { processAuditLog } = await import('./services/audit-log.service.js');
    await processAuditLog(job.data);
  }
}, { connection, concurrency: 50 });

// --- Monitoring & Error Events -----------------------------------------------

notificationWorker.on('completed', (job) => {
  appLogger.info('[Queue] Notification job completed', { jobId: job.id });
});
notificationWorker.on('failed', (job, err) => {
  appLogger.error('[Queue] Notification job failed', { jobId: job?.id, error: err.message });
});

csvImportWorker.on('completed', (job) => {
  appLogger.info('[Queue] CSV import job completed', { jobId: job.id });
});
csvImportWorker.on('failed', (job, err) => {
  appLogger.error('[Queue] CSV import job failed', { jobId: job?.id, error: err.message });
});

mediaWorker.on('completed', (job) => {
  appLogger.info('[Queue] Media upload job completed', { jobId: job.id });
});
mediaWorker.on('failed', (job, err) => {
  appLogger.error('[Queue] Media upload job failed � will retry', { jobId: job?.id, error: err.message, attempts: job?.attemptsMade });
});

auditWorker.on('completed', (job) => {
  appLogger.debug('[Queue] Audit log job completed', { jobId: job.id });
});
auditWorker.on('failed', (job, err) => {
  appLogger.error('[Queue] Audit log job failed', { jobId: job?.id, error: err.message });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  appLogger.info('SIGTERM received: closing workers...');
  await Promise.all([
    notificationWorker.close(),
    csvImportWorker.close(),
    mediaWorker.close(),
    auditWorker.close()
  ]);
  process.exit(0);
});
