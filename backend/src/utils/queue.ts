import { Queue, Worker } from 'bullmq';
import { redis } from './redis.js';
import { appLogger } from './logger.js';
import { processBulkNotifications } from '../notifications/notification.service.js';
import { processCsvImport } from '../admins/admins.csv.js';

// Define the connection to Redis
const connection = redis;

// Create queues
export const notificationQueue = new Queue('notificationQueue', { connection });
export const csvImportQueue = new Queue('csvImportQueue', { connection });
export const mediaQueue = new Queue('mediaQueue', { connection });
export const auditQueue = new Queue('auditQueue', { connection });


