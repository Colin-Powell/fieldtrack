import { Router } from 'express';
import { NotificationController } from './notification.controller.js';

const router = Router();
const controller = new NotificationController();

router.get('/', controller.getUserNotifications.bind(controller));
router.patch('/:id/read', controller.markAsRead.bind(controller));

export default router;
