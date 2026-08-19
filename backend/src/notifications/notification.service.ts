import { prisma } from '../db.js';
import { firebaseAdmin } from '../firebase_admin.js';
import { getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

export class NotificationService {

  /**
   * Prevents sending duplicate notifications within a given timeframe for the same entity and type.
   */
  async hasRecentNotification(recipientId: string, title: string, entityId: string, hours: number = 24): Promise<boolean> {
    const cutoff = new Date(Date.now() - hours * 60 * 60 * 1000);
    const existing = await prisma.notification.findFirst({
      where: {
        recipientId,
        title,
        entityId,
        createdAt: { gte: cutoff }
      }
    });
    return !!existing;
  }
  async sendNotification(data: {
    recipientId: string;
    senderId?: string;
    title: string;
    message: string;
    type: 'CHECKED_IN' | 'CHECKED_OUT' | 'REVIEW_RECEIVED' | 'REVISION_REQUESTED' | 'ACTIVITY_APPROVED' | 'SYSTEM_ALERT' | 'NEW_SUBMISSION' | 'SUPERVISOR_MESSAGE' | 'UPDATE_AVAILABLE';
    entityType?: string;
    entityId?: string;
    actionUrl?: string;
    priority?: number;
  }) {
    const recipient = await prisma.user.findUnique({
      where: { id: data.recipientId },
      include: { preferences: true },
    }) as {
      id: string;
      fcmToken?: string | null;
      email?: string | null;
      preferences?: { chanInApp?: boolean } | null;
    } | null;

    if (!recipient) {
      throw new Error('Notification recipient not found');
    }

    const notification = await prisma.notification.create({
      data: {
        recipientId: data.recipientId,
        senderId: data.senderId,
        title: data.title,
        message: data.message,
        type: data.type,
        entityType: data.entityType,
        entityId: data.entityId,
        actionUrl: data.actionUrl,
        priority: data.priority || 0,
      }
    });

    const hasToken = typeof recipient.fcmToken === 'string' && recipient.fcmToken.trim().length > 0;
    const pushEnabled = recipient.preferences?.chanInApp !== false;
    const shouldSendPush = hasToken && pushEnabled;
    const firebaseReady = getApps().length > 0;
    console.log(`[NOTIFICATION] Preparing to send notification. FCMToken: ${hasToken ? 'YES' : 'NO'}, shouldSendPush: ${shouldSendPush}, pushEnabled: ${pushEnabled}, Firebase initialized: ${firebaseReady}`);
    
    if (shouldSendPush && firebaseReady) {
      try {
        const tokenPreview = (recipient.fcmToken as string).substring(0, 30);
        console.log(`[NOTIFICATION] Sending FCM push to token: ${tokenPreview}...`);
        await getMessaging().send({
          token: recipient.fcmToken as string,
          notification: {
            title: data.title,
            body: data.message,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel_v2',
              sound: 'default',
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
          data: {
            notificationType: data.type,
            entityType: data.entityType ?? '',
            entityId: data.entityId ?? '',
            actionUrl: data.actionUrl ?? '',
          },
        });
        console.log(`[NOTIFICATION] ✓ FCM push sent successfully`);
      } catch (error) {
        console.error('[NOTIFICATION] ✗ Failed to send FCM push notification:', error);
      }
    } else {
      console.log(`[NOTIFICATION] Skipping FCM push. Reason: ${!recipient.fcmToken ? 'No FCM token' : !firebaseReady ? 'Firebase not initialized' : 'User disabled push'}`);
    }

    return notification;
  }

  async getUserNotifications(userId: string, limit = 50, offset = 0) {
    const [data, total] = await Promise.all([
      prisma.notification.findMany({
        where: { recipientId: userId },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.notification.count({ where: { recipientId: userId } }),
    ]);
    return { data, total, limit, offset };
  }

  async markAsRead(id: string) {
    return prisma.notification.update({
      where: { id },
      data: { isRead: true }
    });
  }

  async markAllAsRead(userId: string) {
    return prisma.notification.updateMany({
      where: { recipientId: userId, isRead: false },
      data: { isRead: true }
    });
  }

  async markBulkAsRead(userId: string, ids: string[]) {
    return prisma.notification.updateMany({
      where: { 
        recipientId: userId,
        id: { in: ids },
        isRead: false
      },
      data: { isRead: true }
    });
  }

  async deleteNotification(id: string) {
    return prisma.notification.delete({
      where: { id }
    });
  }

  async deleteBulkNotifications(userId: string, ids: string[]) {
    return prisma.notification.deleteMany({
      where: { 
        recipientId: userId,
        id: { in: ids }
      }
    });
  }
}

export async function processBulkNotifications(data: {
  recipientIds: string[];
  senderId?: string;
  title: string;
  message: string;
  type: any;
  actionUrl?: string;
}) {
  const service = new NotificationService();
  const results = { success: 0, failed: 0 };
  
  for (const recipientId of data.recipientIds) {
    try {
      await service.sendNotification({
        recipientId,
        senderId: data.senderId,
        title: data.title,
        message: data.message,
        type: data.type,
        actionUrl: data.actionUrl,
      });
      results.success++;
    } catch (error) {
      console.error(`Bulk notification failed for user ${recipientId}:`, error);
      results.failed++;
    }
  }
  
  console.log(`Bulk Notification Background Job Completed`, results);
  return results;
}

