import { Queue } from 'bullmq';
import { redis } from './redis.js';
// Define the connection to Redis
const connection = redis;
// Create queues
export const notificationQueue = new Queue('notificationQueue', { connection });
export const csvImportQueue = new Queue('csvImportQueue', { connection });
export const mediaQueue = new Queue('mediaQueue', { connection });
export const auditQueue = new Queue('auditQueue', { connection });
