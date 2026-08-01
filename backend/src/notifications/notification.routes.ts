import { Router } from 'express';
import { NotificationController } from './notification.controller.js';
import { authenticate } from '../auth/auth.middleware.js';

const router = Router();
const controller = new NotificationController();

router.use(authenticate);

router.get('/', controller.getUserNotifications.bind(controller));
router.patch('/:id/read', controller.markAsRead.bind(controller));

export default router;
