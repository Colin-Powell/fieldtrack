import { Request, Response } from 'express';
import { ReviewService } from './review.service.js';

const reviewService = new ReviewService();

export class ReviewController {
  async submitReview(req: Request, res: Response) {
    try {
      const { activityId, reviewerId, rating, comments, status } = req.body;
      
      if (!activityId || !reviewerId || rating === undefined || !status) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      if (!['APPROVED', 'REJECTED', 'REVISION_REQUESTED'].includes(status)) {
        return res.status(400).json({ error: 'Invalid review status' });
      }

      const review = await reviewService.submitReview({
        activityId,
        reviewerId,
        rating,
        comments,
        status
      });

      res.status(201).json(review);
    } catch (error: any) {
      if (error.message.includes('not found') || error.message.includes('already approved')) {
        return res.status(400).json({ error: error.message });
      }
      console.error('[submitReview]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }

  async getReviews(req: Request, res: Response) {
    try {
      const reviewerId = req.user?.userId;
      if (!reviewerId) return res.status(401).json({ error: 'Unauthorized' });
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);
      const offset = parseInt(req.query.offset as string) || 0;
      const result = await reviewService.getReviews(reviewerId, limit, offset);
      res.status(200).json(result);
    } catch (error) {
      console.error('[getReviews]', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  }
}
