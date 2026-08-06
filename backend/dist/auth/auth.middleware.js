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
export function authenticate(req, res, next) {
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
        next();
    }
    catch (err) {
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
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
