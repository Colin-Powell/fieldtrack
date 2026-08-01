import { NotificationService } from './notification.service.js';
const notificationService = new NotificationService();
export class NotificationController {
    async getUserNotifications(req, res) {
        try {
            const user = req.user;
            if (!user) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const notifications = await notificationService.getUserNotifications(user.userId);
            res.status(200).json(notifications);
        }
        catch (error) {
            console.error('[getUserNotifications]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async markAsRead(req, res) {
        try {
            const id = req.params.id;
            const notification = await notificationService.markAsRead(id);
            res.status(200).json(notification);
        }
        catch (error) {
            console.error('[markAsRead]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
}
