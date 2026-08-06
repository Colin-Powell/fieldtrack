import jwt from 'jsonwebtoken';
const JWT_SECRET = process.env.JWT_SECRET;
const EXPIRES_IN = '30m'; // Short-lived access token
const REFRESH_EXPIRES_IN = '7d';
if (!JWT_SECRET) {
    throw new Error('JWT_SECRET must be set in the environment variables.');
}
const jwtSecret = JWT_SECRET;
export function generateToken(payload) {
    return jwt.sign(payload, jwtSecret, { expiresIn: EXPIRES_IN });
}
export function generateRefreshToken(payload) {
    return jwt.sign(payload, jwtSecret, { expiresIn: REFRESH_EXPIRES_IN });
}
export function verifyToken(token) {
    const decoded = jwt.verify(token, jwtSecret, { algorithms: ['HS256'] });
    if (typeof decoded.userId !== 'string' || decoded.userId.trim().length === 0) {
        throw new Error('Invalid token payload: missing userId');
    }
    if (typeof decoded.role !== 'string' || decoded.role.trim().length === 0) {
        throw new Error('Invalid token payload: missing role');
    }
    return {
        userId: decoded.userId,
        role: decoded.role,
        email: typeof decoded.email === 'string' ? decoded.email : undefined,
        permissions: Array.isArray(decoded.permissions) ? decoded.permissions.filter((value) => typeof value === 'string') : undefined,
    };
}
