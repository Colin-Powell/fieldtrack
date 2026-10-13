import { Router } from 'express';
import { getAdminDashboard, getSupervisorDashboard, getStudentDashboard } from './dashboard.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
import { cacheMiddleware } from '../utils/cache.js';

const router = Router();

// Admin Dashboard
router.get('/admin', authenticate, authorizeRole(['ADMIN']), cacheMiddleware(60), getAdminDashboard);

// Supervisor Dashboard
router.get('/supervisor', authenticate, authorizeRole(['SUPERVISOR']), cacheMiddleware(60), getSupervisorDashboard);

// Student Dashboard
router.get('/student', authenticate, authorizeRole(['STUDENT']), cacheMiddleware(60), getStudentDashboard);

export default router;
