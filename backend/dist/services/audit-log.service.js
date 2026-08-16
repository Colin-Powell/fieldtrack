import { prisma } from '../db.js';
import { appLogger } from '../utils/logger.js';
export class AuditLogService {
    /**
     * Log an audit event.
     */
    static async log({ actorId, userId, action, details, ipAddress, userAgent, device, }) {
        try {
            const { auditQueue } = await import('../utils/queue.js');
            await auditQueue.add('logAudit', {
                actorId,
                userId,
                action,
                details: details ? JSON.parse(JSON.stringify(details)) : undefined,
                ipAddress,
                userAgent,
                device,
            });
        }
        catch (error) {
            appLogger.error('Failed to queue audit log:', { error, action, actorId, userId });
        }
    }
}
export async function processAuditLog(data) {
    try {
        await prisma.auditLog.create({
            data: {
                actorId: data.actorId,
                userId: data.userId,
                action: data.action,
                details: data.details,
                ipAddress: data.ipAddress,
                userAgent: data.userAgent,
                device: data.device,
            },
        });
    }
    catch (error) {
        appLogger.error('Failed to write audit log from queue:', { error, action: data.action });
    }
}
