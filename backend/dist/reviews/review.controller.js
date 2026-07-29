import { ReviewService } from './review.service.js';
const reviewService = new ReviewService();
export class ReviewController {
    async submitReview(req, res) {
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
        }
        catch (error) {
            if (error.message.includes('not found') || error.message.includes('already approved')) {
                return res.status(400).json({ error: error.message });
            }
            console.error('[submitReview]', error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }
}
