import { prisma } from '../db.js';

export class ActivityService {
  /**
   * Create a new draft activity
   */
  async createDraft(data: {
    studentId: string;
    title: string;
    description?: string;
    latitude?: number;
    longitude?: number;
    gpsAccuracy?: number;
    methodology?: string;
    objectives?: string;
    findings?: string;
    remarks?: string;
  }) {
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
        status: 'DRAFT',
      },
    });
  }

  /**
   * Update an existing activity (if not locked)
   */
  async updateActivity(id: string, studentId: string, data: {
    title?: string;
    description?: string;
    methodology?: string;
    objectives?: string;
    findings?: string;
    remarks?: string;
  }) {
    const activity = await prisma.fieldLog.findFirst({
      where: { id, studentId },
    });

    if (!activity) {
      throw new Error('Activity not found or unauthorized');
    }

    if (['APPROVED', 'UNDER_REVIEW', 'REJECTED'].includes(activity.status)) {
      throw new Error(`Cannot edit activity in status: ${activity.status}`);
    }

    return prisma.fieldLog.update({
      where: { id },
      data,
    });
  }

  /**
   * Submit an activity for review
   */
  async submitActivity(id: string, studentId: string) {
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
  async getStudentActivities(studentId: string) {
    return prisma.fieldLog.findMany({
      where: { studentId },
      include: {
        evidence: true,
        reviews: true,
      },
      orderBy: { timestamp: 'desc' },
    });
  }

  /**
   * Get an activity by ID
   */
  async getActivity(id: string) {
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
      }
    });
  }

  /**
   * Get activities for assigned students (Supervisor view)
   */
  async getSupervisorActivities(supervisorId: string) {
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
}
