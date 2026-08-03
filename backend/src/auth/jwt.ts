import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;
const EXPIRES_IN = '30m'; // Short-lived access token
const REFRESH_EXPIRES_IN = '7d';

if (!JWT_SECRET) {
  throw new Error('JWT_SECRET must be set in the environment variables.');
}

const jwtSecret: string = JWT_SECRET;

export interface TokenPayload {
  userId: string;
  role: string;
  email?: string;
  permissions?: string[];
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, jwtSecret, { expiresIn: EXPIRES_IN });
}

export function generateRefreshToken(payload: { userId: string }): string {
  return jwt.sign(payload, jwtSecret, { expiresIn: REFRESH_EXPIRES_IN });
}

export function verifyToken(token: string): TokenPayload {
  const decoded = jwt.verify(token, jwtSecret) as jwt.JwtPayload & { userId?: string; role?: string; email?: string; permissions?: string[] };
  return {
    userId: decoded.userId ?? '',
    role: decoded.role ?? 'USER',
    email: decoded.email,
    permissions: decoded.permissions,
  };
}
