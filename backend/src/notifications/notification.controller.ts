import { Request, Response } from 'express';
import { NotificationService } from './notification.service.js';

const notificationService = new NotificationService();

export class NotificationController {
  async getUserNotifications(req: Request, res: Response) {
    try {
      const userId = req.query.userId as string;
      if (!userId) {
        return res.status(400).json({ error: 'Missing userId' });
      }
      const notifications = await notificationService.getUserNotifications(userId);
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
}
