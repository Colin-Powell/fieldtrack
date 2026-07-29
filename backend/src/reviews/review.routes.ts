import { Router } from 'express';
import { ReviewController } from './review.controller.js';

const router = Router();
const controller = new ReviewController();

router.post('/', controller.submitReview.bind(controller));

export default router;
