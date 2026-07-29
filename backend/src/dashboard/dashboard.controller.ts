import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

export async function getAdminDashboard(req: Request, res: Response) {
  try {
    const totalStudents = await prisma.user.count({ where: { role: 'STUDENT' } });
    const activeSupervisors = await prisma.user.count({ where: { role: 'SUPERVISOR' } });
    
    // For now, mock the project counts since we don't have a Project model yet
    const activeProjects = 14; 
    const pendingReviews = 5;

    res.json({
      totalStudents,
      activeSupervisors,
      activeProjects,
      pendingReviews,
    });
  } catch (error) {
    console.error('Admin Dashboard Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

export async function getSupervisorDashboard(req: Request, res: Response) {
  try {
    const supervisorId = req.user?.userId;
    
    let assignedStudentIds: string[] = [];
    let supervisor = null;
    
    if (supervisorId) {
      const supervisorProfile = await prisma.supervisorProfile.findUnique({
        where: { userId: supervisorId },
        include: { assignedStudents: true, user: true }
      });
      if (supervisorProfile) {
        supervisor = {
          name: supervisorProfile.user.name,
          avatarUrl: supervisorProfile.user.avatarUrl ?? null,
          department: supervisorProfile.department,
        };
        assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
      }
    } 
    
    // Fallback: If no supervisorId or no students assigned, show all students for testing purposes
    if (assignedStudentIds.length === 0) {
      const allStudents = await prisma.studentProfile.findMany();
      assignedStudentIds = allStudents.map(s => s.userId);
      if (!supervisor) supervisor = { name: "Guest Supervisor", avatarUrl: null, department: "General" };
    }
    
    const studentsInField = await prisma.studentProfile.count({ where: { userId: { in: assignedStudentIds }, status: 'IN_FIELD' } });
    const checkedOut = await prisma.studentProfile.count({ where: { userId: { in: assignedStudentIds }, status: 'CHECKED_OUT' } });
    const checkedIn = await prisma.studentProfile.count({ where: { userId: { in: assignedStudentIds }, status: 'IDLE' } });
    
    // Stats calculation
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const pendingApprovals = await prisma.fieldLog.count({
      where: {
        studentId: { in: assignedStudentIds },
        status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] }
      }
    });

    const recentLogs = await prisma.fieldLog.findMany({
      where: { studentId: { in: assignedStudentIds } },
      take: 10,
      orderBy: { timestamp: 'desc' },
      include: { user: true }
    });
    
    const logsToday = await prisma.fieldLog.count({
      where: { studentId: { in: assignedStudentIds }, timestamp: { gte: today } }
    });
    const logsYesterday = await prisma.fieldLog.count({
      where: { studentId: { in: assignedStudentIds }, timestamp: { gte: yesterday, lt: today } }
    });
    const logsTrend = logsYesterday === 0 ? 100 : Math.round(((logsToday - logsYesterday) / logsYesterday) * 100);

    const activeSessions = await prisma.fieldSession.findMany({
      where: { studentId: { in: assignedStudentIds }, status: 'ACTIVE' },
      include: { user: { include: { studentProfile: true } } }
    });

    const checkInsToday = await prisma.fieldSession.count({
      where: { studentId: { in: assignedStudentIds }, checkInTime: { gte: today } }
    });
    
    const checkInsYesterday = await prisma.fieldSession.count({
      where: { studentId: { in: assignedStudentIds }, checkInTime: { gte: yesterday, lt: today } }
    });
    
    const checkInsTrend = checkInsYesterday === 0 ? (checkInsToday > 0 ? 100 : 0) : Math.round(((checkInsToday - checkInsYesterday) / checkInsYesterday) * 100);

    res.json({
      supervisor,
      statistics: {
        checkedOut,
        checkedIn,
        studentsInField,
        pendingApprovals,
        activitiesSubmitted: logsToday,
      },
      trend: {
        activities: logsTrend > 0 ? `+${logsTrend}%` : `${logsTrend}%`,
        checkIns: checkInsTrend > 0 ? `+${checkInsTrend}%` : `${checkInsTrend}%`,
      },
      assignedStudents: assignedStudentIds.length,
      studentsCheckedIn: checkInsToday,
      pendingReviews: pendingApprovals,
      approvedToday: 0,
      rejectedToday: 0,
      averageReviewTime: "2 hours",
      recentActivities: recentLogs,
      notifications: [],
      upcomingDeadlines: [],
      activeFieldSessions: activeSessions,
      mapSummary: [],
      workload: "Medium",
      completionRate: "78%"
    });
  } catch (error) {
    console.error('Supervisor Dashboard Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

export async function getStudentDashboard(req: Request, res: Response) {
  try {
    const userId = req.user?.userId;
    
    const profile = await prisma.studentProfile.findUnique({ where: { userId } });
    
    res.json({
      status: profile?.status ?? 'IDLE',
      hoursLogged: 42,
      approvals: 12,
      recentLogs: []
    });
  } catch (error) {
    console.error('Student Dashboard Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}
