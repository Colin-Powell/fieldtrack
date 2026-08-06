import { Request, Response } from 'express';
import { NotificationService } from './notification.service.js';

const notificationService = new NotificationService();

export class NotificationController {
  async getUserNotifications(req: Request, res: Response) {
    try {
      const user = req.user;
      if (!user) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
      const notifications = await notificationService.getUserNotifications(user.userId);
      res.status(200).json(notifications);
    } catch (error) {
      console.error('[getUserNotifications]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async markAsRead(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const notification = await notificationService.markAsRead(id);
      res.status(200).json(notification);
    } catch (error) {
      console.error('[markAsRead]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async markAllAsRead(req: Request, res: Response) {
    try {
      const user = req.user;
      if (!user) return res.status(401).json({ error: 'Unauthorized' });
      await notificationService.markAllAsRead(user.userId);
      res.status(200).json({ success: true });
    } catch (error) {
      console.error('[markAllAsRead]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async markBulkAsRead(req: Request, res: Response) {
    try {
      const user = req.user;
      const ids = req.body.ids;
      if (!user) return res.status(401).json({ error: 'Unauthorized' });
      if (!Array.isArray(ids)) return res.status(400).json({ error: 'ids array required' });
      await notificationService.markBulkAsRead(user.userId, ids);
      res.status(200).json({ success: true });
    } catch (error) {
      console.error('[markBulkAsRead]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async deleteNotification(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      await notificationService.deleteNotification(id);
      res.status(200).json({ success: true });
    } catch (error) {
      console.error('[deleteNotification]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async deleteBulkNotifications(req: Request, res: Response) {
    try {
      const user = req.user;
      const ids = req.body.ids;
      if (!user) return res.status(401).json({ error: 'Unauthorized' });
      if (!Array.isArray(ids)) return res.status(400).json({ error: 'ids array required' });
      await notificationService.deleteBulkNotifications(user.userId, ids);
      res.status(200).json({ success: true });
    } catch (error) {
      console.error('[deleteBulkNotifications]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
}
