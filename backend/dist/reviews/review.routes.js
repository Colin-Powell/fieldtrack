import { Router } from 'express';
import { ReviewController } from './review.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
const router = Router();
const controller = new ReviewController();
// Only SUPERVISOR may submit a review (approve/reject an activity)
router.post('/', authenticate, authorizeRole(['SUPERVISOR']), controller.submitReview.bind(controller));
export default router;
