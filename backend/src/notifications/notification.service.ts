import { prisma } from '../db.js';

export class NotificationService {
  async sendNotification(data: {
    recipientId: string;
    senderId?: string;
    title: string;
    message: string;
    type: 'CHECKED_IN' | 'CHECKED_OUT' | 'REVIEW_RECEIVED' | 'REVISION_REQUESTED' | 'ACTIVITY_APPROVED' | 'SYSTEM_ALERT' | 'NEW_SUBMISSION' | 'SUPERVISOR_MESSAGE';
    entityType?: string;
    entityId?: string;
    priority?: number;
  }) {
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

  async getUserNotifications(userId: string) {
    return prisma.notification.findMany({
      where: { recipientId: userId },
      orderBy: { createdAt: 'desc' },
      take: 50
    });
  }

  async markAsRead(id: string) {
    return prisma.notification.update({
      where: { id },
      data: { isRead: true }
    });
  }
}
