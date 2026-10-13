import { NotificationService } from './notification.service.js';
const notificationService = new NotificationService();
export class NotificationController {
    async getUserNotifications(req, res) {
        try {
            const user = req.user;
            if (!user) {
                return res.status(401).json({ error: 'Unauthorized' });
            }
            const limit = Math.min(parseInt(req.query.limit) || 50, 200);
            const offset = parseInt(req.query.offset) || 0;
            const result = await notificationService.getUserNotifications(user.userId, limit, offset);
            res.status(200).json(result);
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
    async markAllAsRead(req, res) {
        try {
            const user = req.user;
            if (!user)
                return res.status(401).json({ error: 'Unauthorized' });
            await notificationService.markAllAsRead(user.userId);
            res.status(200).json({ success: true });
        }
        catch (error) {
            console.error('[markAllAsRead]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async markBulkAsRead(req, res) {
        try {
            const user = req.user;
            const ids = req.body.ids;
            if (!user)
                return res.status(401).json({ error: 'Unauthorized' });
            if (!Array.isArray(ids))
                return res.status(400).json({ error: 'ids array required' });
            await notificationService.markBulkAsRead(user.userId, ids);
            res.status(200).json({ success: true });
        }
        catch (error) {
            console.error('[markBulkAsRead]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async deleteNotification(req, res) {
        try {
            const id = req.params.id;
            await notificationService.deleteNotification(id);
            res.status(200).json({ success: true });
        }
        catch (error) {
            console.error('[deleteNotification]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
    async deleteBulkNotifications(req, res) {
        try {
            const user = req.user;
            const ids = req.body.ids;
            if (!user)
                return res.status(401).json({ error: 'Unauthorized' });
            if (!Array.isArray(ids))
                return res.status(400).json({ error: 'ids array required' });
            await notificationService.deleteBulkNotifications(user.userId, ids);
            res.status(200).json({ success: true });
        }
        catch (error) {
            console.error('[deleteBulkNotifications]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
}
