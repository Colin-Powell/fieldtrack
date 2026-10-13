import { Router } from 'express';
import { authenticate } from '../auth/auth.middleware.js';
import { authorizeRole } from '../auth/auth.middleware.js';
import { cacheMiddleware } from '../utils/cache.js';
import { getDashboardStats, getDashboardRecentActivities, getDashboardFeed, getDashboardPendingReviews, getStudents, getStudentById, getStudentActivities, getStudentActivityById, getStudentDailyLogs, getStudentActivityEvidence, getStudentLocation, getStudentTimeline, getStudentNotifications, getLiveMapLocations, generateReport, exportLogs } from './supervisor.controller.js';
const router = Router();
// Protect all supervisor routes
router.use(authenticate, authorizeRole(['SUPERVISOR']));
// Dashboard
router.get('/dashboard/stats', cacheMiddleware(60), getDashboardStats);
router.get('/dashboard/recent-activities', getDashboardRecentActivities);
router.get('/dashboard/feed', getDashboardFeed);
router.get('/dashboard/pending-reviews', getDashboardPendingReviews);
// Students
router.get('/students', getStudents);
router.get('/students/:id', getStudentById);
router.get('/students/:id/activities', getStudentActivities);
router.get('/students/:id/activities/:activityId', getStudentActivityById);
router.get('/students/:id/logs', getStudentDailyLogs);
router.get('/students/:id/activities/:activityId/evidence', getStudentActivityEvidence);
router.get('/students/:id/location', getStudentLocation);
router.get('/students/:id/timeline', getStudentTimeline);
router.get('/students/:id/notifications', getStudentNotifications);
// Map
router.get('/map/live', getLiveMapLocations);
// Reports and Logs
router.post('/reports/generate', generateReport);
router.get('/logs/export', exportLogs);
export default router;
