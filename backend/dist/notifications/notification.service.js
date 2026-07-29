import { prisma } from '../db.js';
export class NotificationService {
    async sendNotification(data) {
        return prisma.notification.create({
            data: {
                recipientId: data.recipientId,
                senderId: data.senderId,
                title: data.title,
                message: data.message,
                type: data.type,
                entityType: data.entityType,
                entityId: data.entityId,
                priority: data.priority || 0,
            }
        });
    }
    async getUserNotifications(userId) {
        return prisma.notification.findMany({
            where: { recipientId: userId },
            orderBy: { createdAt: 'desc' },
            take: 50
        });
    }
    async markAsRead(id) {
        return prisma.notification.update({
            where: { id },
            data: { isRead: true }
        });
    }
}
