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
    const decoded = jwt.verify(token, jwtSecret);
    return {
        userId: decoded.userId ?? '',
        role: decoded.role ?? 'USER',
        email: decoded.email,
        permissions: decoded.permissions,
    };
}
