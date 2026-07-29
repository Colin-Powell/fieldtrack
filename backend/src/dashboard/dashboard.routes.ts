import { Router } from 'express';
import { getAdminDashboard, getSupervisorDashboard, getStudentDashboard } from './dashboard.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';

const router = Router();

// Admin Dashboard
router.get('/admin', authenticate, authorizeRole(['ADMIN']), getAdminDashboard);

// Supervisor Dashboard
router.get('/supervisor', authenticate, authorizeRole(['SUPERVISOR']), getSupervisorDashboard);

// Student Dashboard
router.get('/student', authenticate, authorizeRole(['STUDENT']), getStudentDashboard);

export default router;
