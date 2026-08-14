import { prisma } from '../db.js';
import { reverseGeocode } from '../utils/geocoder.js';
export class ActivityService {
    /**
     * Create a new draft activity
     */
    async createDraft(data) {
        let locationName = null;
        let county = null;
        if (data.latitude && data.longitude) {
            const geo = await reverseGeocode(data.latitude, data.longitude);
            locationName = geo.locationName ?? undefined;
            county = geo.county ?? undefined;
        }
        return prisma.fieldLog.create({
            data: {
                studentId: data.studentId,
                title: data.title,
                description: data.description,
                latitude: data.latitude,
                longitude: data.longitude,
                gpsAccuracy: data.gpsAccuracy,
                methodology: data.methodology,
                objectives: data.objectives,
                findings: data.findings,
                remarks: data.remarks,
                locationName,
                county,
                status: 'DRAFT',
            },
        });
    }
    /**
     * Update an existing activity (if not locked)
     */
    async updateActivity(id, studentId, data) {
        const activity = await prisma.fieldLog.findFirst({
            where: { id, studentId },
        });
        if (!activity) {
            throw new Error('Activity not found or unauthorized');
        }
        if (['APPROVED', 'UNDER_REVIEW', 'SUBMITTED', 'RESUBMITTED'].includes(activity.status)) {
            throw new Error(`Cannot edit activity in status: ${activity.status}`);
        }
        return prisma.fieldLog.update({
            where: { id },
            data: {
                ...data,
                status: 'DRAFT',
            },
        });
    }
    /**
     * Submit an activity for review
     */
    async submitActivity(id, studentId) {
        const activity = await prisma.fieldLog.findFirst({
            where: { id, studentId },
        });
        if (!activity) {
            throw new Error('Activity not found or unauthorized');
        }
        if (activity.status !== 'DRAFT' && activity.status !== 'REVISION_REQUESTED') {
            throw new Error(`Cannot submit activity in status: ${activity.status}`);
        }
        const newStatus = activity.status === 'REVISION_REQUESTED' ? 'RESUBMITTED' : 'SUBMITTED';
        return prisma.fieldLog.update({
            where: { id },
            data: { status: newStatus },
        });
    }
    /**
     * Get all activities for a student
     */
    async getStudentActivities(studentId) {
        return prisma.fieldLog.findMany({
            where: { studentId },
            include: {
                evidence: true,
                reviews: true,
                user: { select: { id: true, name: true, email: true } },
            },
            orderBy: { timestamp: 'desc' },
        });
    }
    /**
     * Get an activity by ID
     */
    async getActivity(id) {
        return prisma.fieldLog.findUnique({
            where: { id },
            include: {
                evidence: true,
                reviews: {
                    include: {
                        reviewer: {
                            select: { id: true, name: true, role: true }
                        }
                    }
                },
                user: { select: { id: true, name: true, email: true } },
            }
        });
    }
    /**
     * Get activities for assigned students (Supervisor view)
     */
    async getSupervisorActivities(supervisorId) {
        const supervisorProfile = await prisma.supervisorProfile.findUnique({
            where: { userId: supervisorId },
            include: { assignedStudents: true }
        });
        if (!supervisorProfile) {
            throw new Error('Supervisor profile not found');
        }
        const studentIds = supervisorProfile.assignedStudents.map(s => s.userId);
        return prisma.fieldLog.findMany({
            where: {
                studentId: { in: studentIds },
                status: { in: ['SUBMITTED', 'UNDER_REVIEW', 'RESUBMITTED', 'REVISION_REQUESTED', 'APPROVED', 'REJECTED'] }
            },
            include: {
                evidence: true,
                user: { select: { id: true, name: true, email: true } },
            },
            orderBy: { timestamp: 'desc' },
        });
    }
    /**
     * Hard delete an activity by ID
     */
    async deleteActivity(id, studentId) {
        const activity = await prisma.fieldLog.findUnique({ where: { id } });
        if (!activity) {
            throw new Error('Activity not found');
        }
        if (activity.studentId !== studentId) {
            throw new Error('Unauthorized');
        }
        // Delete associated evidence, reviews, etc.
        // Assuming cascade delete is set up in Prisma or we do it manually.
        // Let's manually delete child records to be safe before deleting the fieldLog.
        await prisma.evidence.deleteMany({ where: { activityId: id } });
        await prisma.review.deleteMany({ where: { activityId: id } });
        return prisma.fieldLog.delete({ where: { id } });
    }
}
