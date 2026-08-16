import { Request, Response, NextFunction } from 'express';
import { redis } from './redis.js';

/**
 * Express middleware to cache responses in Redis
 * @param durationInSeconds Time to live (TTL) for the cache
 */
export function cacheMiddleware(durationInSeconds: number) {
  return async (req: Request, res: Response, next: NextFunction) => {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next();
    }

    // Include userId in the cache key if authenticated to prevent leaking user-specific data
    const userId = (req as any).user?.userId || 'anonymous';
    const key = `cache:${userId}:${req.originalUrl || req.url}`;
    
    try {
      const cachedData = await redis.get(key);
      if (cachedData) {
        res.setHeader('X-Cache', 'HIT');
        return res.status(200).json(JSON.parse(cachedData));
      }

      // Intercept response.send to cache the payload
      const originalSend = res.send.bind(res);
      res.send = (body: any) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          redis.setex(key, durationInSeconds, body).catch(err => {
            console.error('[Cache Set Error]', err);
          });
        }
        res.setHeader('X-Cache', 'MISS');
        return originalSend(body);
      };

      next();
    } catch (err) {
      console.error('[Cache Middleware Error]', err);
      next(); // fallback to standard route execution
    }
  };
}

/**
 * Invalidate all cached responses for a specific user.
 * Call this after any write that changes user-scoped data.
 */
export async function invalidateUserCache(userId: string): Promise<void> {
  try {
    const keys = await redis.keys(`cache:${userId}:*`);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  } catch (err) {
    console.error('[Cache Invalidation Error]', err);
  }
}

/**
 * Invalidate a single specific cache key (e.g., a shared/global endpoint).
 */
export async function invalidateCache(key: string): Promise<void> {
  try {
    await redis.del(key);
  } catch (err) {
    console.error('[Cache Invalidation Error]', err);
  }
}

/**
 * Invalidate all cached responses for the global 'anonymous' scope
 * (e.g., shared dashboard aggregates not scoped to a single user).
 */
export async function invalidateGlobalCache(urlPattern: string): Promise<void> {
  try {
    const keys = await redis.keys(`cache:*:${urlPattern}*`);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  } catch (err) {
    console.error('[Cache Invalidation Error]', err);
  }
}
