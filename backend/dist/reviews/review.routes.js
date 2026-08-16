import { Router } from 'express';
import { ReviewController } from './review.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
const router = Router();
const controller = new ReviewController();
// Only SUPERVISOR may submit a review (approve/reject an activity)
router.post('/', authenticate, authorizeRole(['SUPERVISOR']), controller.submitReview.bind(controller));
// Supervisors can list their own submitted reviews (paginated)
router.get('/', authenticate, authorizeRole(['SUPERVISOR', 'ADMIN']), controller.getReviews.bind(controller));
export default router;
