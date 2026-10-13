import { verifyToken } from './jwt.js';
function parseCookieHeader(cookieHeader) {
    if (!cookieHeader) {
        return {};
    }
    return cookieHeader.split(';').reduce((accumulator, part) => {
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
export async function authenticate(req, res, next) {
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
        const deviceId = req.headers['x-device-id'];
        if (deviceId) {
            const { prisma } = await import('../db.js');
            const deviceSession = await prisma.deviceSession.findFirst({
                where: {
                    userId: payload.userId,
                    deviceId: deviceId,
                    isActive: true,
                },
            });
            if (!deviceSession) {
                return res.status(401).json({ error: 'Unauthorized: Device not recognized or session revoked' });
            }
        }
        next();
    }
    catch (err) {
        return res.status(401).json({ error: 'Unauthorized: Invalid token or session error' });
    }
}
export async function authenticateDashboard(req, res, next) {
    const cookies = parseCookieHeader(req.headers.cookie);
    const token = cookies.fieldtrack_developer_token?.trim();
    const clearCookieAndRedirect = () => {
        res.clearCookie('fieldtrack_developer_token', { path: '/' });
        return res.redirect('/developer-login?expired=1');
    };
    if (!token) {
        return clearCookieAndRedirect();
    }
    try {
        const payload = verifyToken(token);
        if (payload.role !== 'ADMIN') {
            return clearCookieAndRedirect();
        }
        req.user = payload;
        next();
    }
    catch (err) {
        return clearCookieAndRedirect();
    }
}
export function authorizeRole(roles) {
    return (req, res, next) => {
        if (!req.user || !roles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Forbidden: Insufficient role permissions' });
        }
        next();
    };
}
