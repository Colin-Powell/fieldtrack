import { Router } from 'express';
import { SessionController } from './session.controller.js';
// In a real app we would import auth middleware to protect these routes
// import { requireAuth } from '../middleware/auth.middleware.js';

const router = Router();
const controller = new SessionController();

// Create a new field session (Check-In)
router.post('/checkin', controller.checkIn.bind(controller));

// End a field session (Check-Out)
router.patch('/checkout', controller.checkOut.bind(controller));

// Get active session
router.get('/active', controller.getActive.bind(controller));

// Log a location ping
router.post('/ping', controller.logPing.bind(controller));

// Get all location pings for a student (supervisor view)
router.get('/student/:studentId/pings', controller.getStudentPings.bind(controller));

export default router;
