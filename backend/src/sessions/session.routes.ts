import { Router } from 'express';
import { SessionController } from './session.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';

const router = Router();
const controller = new SessionController();

// ── Student-only session operations ────────────────────────────────────────
// Only a STUDENT may start, end, or ping their own session.
router.post('/checkin',  authenticate, authorizeRole(['STUDENT']), controller.checkIn.bind(controller));
router.patch('/checkout', authenticate, authorizeRole(['STUDENT']), controller.checkOut.bind(controller));
router.get('/active',    authenticate, authorizeRole(['STUDENT']), controller.getActive.bind(controller));
router.post('/ping',     authenticate, authorizeRole(['STUDENT']), controller.logPing.bind(controller));
router.post('/batch-pings', authenticate, authorizeRole(['STUDENT']), controller.logBatchPings.bind(controller));

// ── Supervisor-only read access ────────────────────────────────────────────
// Only a SUPERVISOR may view a student's location ping history.
router.get('/student/:studentId/pings', authenticate, authorizeRole(['SUPERVISOR']), controller.getStudentPings.bind(controller));

export default router;
