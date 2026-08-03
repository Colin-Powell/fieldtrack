import { prisma } from '../db.js';
import { appLogger } from '../utils/logger.js';
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
            appLogger.error('Failed to write audit log:', { error, action, actorId, userId });
        }
    }
}
