import { Request, Response, NextFunction } from 'express';
import { verifyToken, TokenPayload } from './jwt.js';

// Augment Express Request object to include user
declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

function parseCookieHeader(cookieHeader: string | undefined): Record<string, string> {
  if (!cookieHeader) {
    return {};
  }

  return cookieHeader.split(';').reduce<Record<string, string>>((accumulator, part) => {
    const [rawName, ...rawValue] = part.trim().split('=');
    if (!rawName) {
      return accumulator;
    }

    const name = decodeURIComponent(rawName);
    const value = rawValue.join('=').trim();
    accumulator[name] = value ? decodeURIComponent(value) : '';
    return accumulator;
  }, {});
}

export async function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  const cookies = parseCookieHeader(req.headers.cookie);
  const cookieToken = cookies.fieldtrack_developer_token;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7).trim() : cookieToken?.trim();

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  try {
    const payload = verifyToken(token);
    req.user = payload;

    const deviceId = req.headers['x-device-id'] as string | undefined;
    if (deviceId) {
      const { prisma } = await import('../db.js');
      const deviceSession = await prisma.deviceSession.findFirst({
        where: {
          userId: payload.id,
          deviceId: deviceId,
          isActive: true,
        },
      });

      if (!deviceSession) {
        return res.status(401).json({ error: 'Unauthorized: Device not recognized or session revoked' });
      }
    }

    next();
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized: Invalid token or session error' });
  }
}

export function authorizeRole(roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden: Insufficient role permissions' });
    }
    next();
  };
}
