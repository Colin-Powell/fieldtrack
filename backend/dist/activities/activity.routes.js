import { Router } from 'express';
import { ActivityController } from './activity.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
const router = Router();
const controller = new ActivityController();
// All activity routes require authentication
router.use(authenticate);
// ── Student-only operations ────────────────────────────────────────────────
// Only a STUDENT may create, edit, or submit their own activities.
router.post('/', authorizeRole(['STUDENT']), controller.create.bind(controller));
router.put('/:id', authorizeRole(['STUDENT']), controller.update.bind(controller));
router.delete('/:id', authorizeRole(['STUDENT']), controller.delete.bind(controller));
router.post('/:id/submit', authorizeRole(['STUDENT']), controller.submit.bind(controller));
// ── Student reads their own activities (Also readable by Supervisor and Admin) ────────────────────────────────────
router.get('/student/all', authorizeRole(['STUDENT', 'SUPERVISOR', 'ADMIN']), controller.getForStudent.bind(controller));
// ── Supervisor reads their assigned students' activities ──────────────────
router.get('/supervisor/all', authorizeRole(['SUPERVISOR']), controller.getForSupervisor.bind(controller));
// ── Single activity readable by both the owning student and their supervisor
router.get('/:id', authorizeRole(['STUDENT', 'SUPERVISOR']), controller.getById.bind(controller));
export default router;
