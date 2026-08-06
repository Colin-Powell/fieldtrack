import { Router } from 'express';
import { ActivityController } from './activity.controller.js';
import { authenticate } from '../auth/auth.middleware.js';

const router = Router();
const controller = new ActivityController();

// Apply authenticate middleware to all activity routes
router.use(authenticate);

// Create draft
router.post('/', controller.create.bind(controller));

// Update draft
router.put('/:id', controller.update.bind(controller));

// Submit for review
router.post('/:id/submit', controller.submit.bind(controller));

// Get activity by ID
router.get('/:id', controller.getById.bind(controller));

// Get all for student
router.get('/student/all', controller.getForStudent.bind(controller));

// Get all for supervisor
router.get('/supervisor/all', controller.getForSupervisor.bind(controller));

export default router;
