import { Redis } from 'ioredis';
import dotenv from 'dotenv';
dotenv.config();
const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
const redisConfig = {
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
    retryStrategy(times) {
        const delay = Math.min(times * 50, 2000);
        return delay;
    },
};
export const redis = new Redis(redisUrl, redisConfig);
export const redisSubscriber = new Redis(redisUrl, redisConfig);
redis.on('error', (err) => {
    console.error('[Redis Error]', err);
});
redis.on('connect', () => {
    console.log('[Redis] Connected successfully');
});
