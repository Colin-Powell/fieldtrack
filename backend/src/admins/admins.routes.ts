import { Router } from 'express';
import { 
  createStudent, createSupervisor, getAllUsers,
  getUserById, updateUser, updateUserStatus,
  reassignSupervisor, resetUserPassword, deleteUser,
  getDepartments, getProjects, getAuditLogs,
  getNotifications, broadcastNotification,
  getSettings, updateSettings, getMapData
} from './admins.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';

const router = Router();

// Protect all admin routes
router.use(authenticate, authorizeRole(['ADMIN']));

// User management routes
router.post('/users/students', createStudent);
router.post('/users/supervisors', createSupervisor);
router.get('/users', getAllUsers);
router.get('/users/:id', getUserById);
router.put('/users/:id', updateUser);
router.patch('/users/:id/status', updateUserStatus);
router.patch('/users/:id/supervisor', reassignSupervisor);
router.post('/users/:id/reset-password', resetUserPassword);
router.delete('/users/:id', deleteUser);

// Department & Project routes
router.get('/departments', getDepartments);
router.get('/projects', getProjects);

// Audit log routes
router.get('/audit-logs', getAuditLogs);

// Notification routes
router.get('/notifications', getNotifications);
router.post('/notifications/broadcast', broadcastNotification);

// Settings routes
router.get('/settings', getSettings);
router.put('/settings', updateSettings);

// Map data route
router.get('/map', getMapData);

export default router;
