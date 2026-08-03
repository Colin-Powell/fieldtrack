import { prisma } from '../db.js';
import { firebaseAdmin } from '../firebase_admin.js';
export class NotificationService {
    async sendNotification(data) {
        const recipient = await prisma.user.findUnique({
            where: { id: data.recipientId },
            select: {
                id: true,
                fcmToken: true,
                email: true,
                preferences: true,
            },
        });
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
                priority: data.priority || 0,
            }
        });
        const shouldSendPush = recipient.fcmToken && (recipient.preferences?.chanInApp !== false);
        console.log(`[NOTIFICATION] Preparing to send notification. FCMToken: ${recipient.fcmToken ? 'YES' : 'NO'}, shouldSendPush: ${shouldSendPush}, Firebase initialized: ${firebaseAdmin.apps.length > 0}`);
        if (shouldSendPush && firebaseAdmin.apps.length > 0) {
            try {
                const tokenPreview = recipient.fcmToken.substring(0, 30);
                console.log(`[NOTIFICATION] Sending FCM push to token: ${tokenPreview}...`);
                await firebaseAdmin.messaging().send({
                    token: recipient.fcmToken,
                    notification: {
                        title: data.title,
                        body: data.message,
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'high_importance_channel',
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
                    },
                });
                console.log(`[NOTIFICATION] ✓ FCM push sent successfully`);
            }
            catch (error) {
                console.error('[NOTIFICATION] ✗ Failed to send FCM push notification:', error);
            }
        }
        else {
            console.log(`[NOTIFICATION] Skipping FCM push. Reason: ${!recipient.fcmToken ? 'No FCM token' : !firebaseAdmin.apps.length ? 'Firebase not initialized' : 'User disabled push'}`);
        }
        return notification;
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
