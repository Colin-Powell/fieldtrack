import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
export async function getAdminDashboard(req, res) {
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
    }
    catch (error) {
        console.error('Admin Dashboard Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
}
export async function getSupervisorDashboard(req, res) {
    try {
        const supervisorId = req.user?.userId;
        // Fallback for missing auth in this test phase
        let assignedStudentIds = [];
        if (supervisorId) {
            const supervisorProfile = await prisma.supervisorProfile.findUnique({
                where: { userId: supervisorId },
                include: { assignedStudents: true }
            });
            assignedStudentIds = supervisorProfile?.assignedStudents.map(s => s.userId) || [];
        }
        else {
            // If no auth, just get all students for demonstration
            const allStudents = await prisma.studentProfile.findMany();
            assignedStudentIds = allStudents.map(s => s.userId);
        }
        const studentsInField = await prisma.studentProfile.count({ where: { userId: { in: assignedStudentIds }, status: 'IN_FIELD' } });
        const checkedOut = await prisma.studentProfile.count({ where: { userId: { in: assignedStudentIds }, status: 'CHECKED_OUT' } });
        const checkedIn = await prisma.studentProfile.count({ where: { userId: { in: assignedStudentIds }, status: 'IDLE' } });
        const pendingApprovals = await prisma.fieldLog.count({
            where: {
                studentId: { in: assignedStudentIds },
                status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] }
            }
        });
        const recentLogs = await prisma.fieldLog.findMany({
            where: { studentId: { in: assignedStudentIds } },
            take: 5,
            orderBy: { timestamp: 'desc' },
            include: { user: true }
        });
        res.json({
            checkedOut,
            checkedIn,
            studentsInField,
            pendingApprovals,
            recentLogs,
        });
    }
    catch (error) {
        console.error('Supervisor Dashboard Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
}
export async function getStudentDashboard(req, res) {
    try {
        const userId = req.user?.userId;
        const profile = await prisma.studentProfile.findUnique({ where: { userId } });
        res.json({
            status: profile?.status ?? 'IDLE',
            hoursLogged: 42,
            approvals: 12,
            recentLogs: []
        });
    }
    catch (error) {
        console.error('Student Dashboard Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
}
