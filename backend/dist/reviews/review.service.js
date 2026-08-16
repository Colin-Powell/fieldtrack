import { prisma } from '../db.js';
import { NotificationService } from '../notifications/notification.service.js';
const notificationService = new NotificationService();
export class ReviewService {
    /**
     * Submit a review for a field log (activity).
     */
    async submitReview(data) {
        const activity = await prisma.fieldLog.findUnique({
            where: { id: data.activityId }
        });
        if (!activity) {
            throw new Error('Activity not found');
        }
        if (activity.status === 'APPROVED') {
            throw new Error('Activity is already approved.');
        }
        // Create the review
        const review = await prisma.review.create({
            data: {
                activityId: data.activityId,
                reviewerId: data.reviewerId,
                rating: data.rating,
                comments: data.comments,
                status: data.status,
            }
        });
        // Update the activity status
        await prisma.fieldLog.update({
            where: { id: data.activityId },
            data: { status: data.status }
        });
        // Send notification to the student
        let notificationType = 'REVIEW_RECEIVED';
        if (data.status === 'APPROVED')
            notificationType = 'ACTIVITY_APPROVED';
        if (data.status === 'REVISION_REQUESTED')
            notificationType = 'REVISION_REQUESTED';
        try {
            await notificationService.sendNotification({
                recipientId: activity.studentId,
                senderId: data.reviewerId,
                title: `Activity ${data.status.replace('_', ' ')}`,
                message: data.comments || `Your activity "${activity.title}" was ${data.status.toLowerCase()}.`,
                type: notificationType,
                entityType: 'FIELD_LOG',
                entityId: activity.id,
                priority: data.status === 'REVISION_REQUESTED' ? 1 : 0
            });
        }
        catch (notificationError) {
            console.error('[submitReview] Failed to send notification:', notificationError.message);
            // Continue - notification failure should not fail the review submission
        }
        return review;
    }
    /**
     * List reviews for a given reviewer (supervisor) with pagination.
     */
    async getReviews(reviewerId, limit = 50, offset = 0) {
        const [data, total] = await Promise.all([
            prisma.review.findMany({
                where: { reviewerId },
                orderBy: { createdAt: 'desc' },
                take: limit,
                skip: offset,
                include: { log: { select: { title: true, studentId: true } } },
            }),
            prisma.review.count({ where: { reviewerId } }),
        ]);
        return { data, total, limit, offset };
    }
}
