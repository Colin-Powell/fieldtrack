import { Router } from 'express';
import { getSupervisorReports } from './reports.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
const router = Router();
// Apply auth middleware to all routes
router.use(authenticate);
router.use(authorizeRole(['SUPERVISOR', 'ADMIN']));
router.get('/supervisor', getSupervisorReports);
export default router;
