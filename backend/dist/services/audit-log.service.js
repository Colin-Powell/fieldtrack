import { prisma } from '../db.js';
export class AuditLogService {
    /**
     * Log an audit event.
     */
    static async log({ actorId, userId, action, details, ipAddress, userAgent, device, }) {
        try {
            await prisma.auditLog.create({
                data: {
                    actorId,
                    userId,
                    action,
                    details: details ? JSON.parse(JSON.stringify(details)) : undefined,
                    ipAddress,
                    userAgent,
                    device,
                },
            });
        }
        catch (error) {
            console.error('Failed to write audit log:', error);
            // In a real enterprise system we might log this to a file or external monitoring service
        }
    }
}
