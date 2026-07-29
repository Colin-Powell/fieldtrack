import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
export async function getAdminDashboard(req, res) {
    try {
        // ── General Stats ──
        const totalStudents = await prisma.user.count({ where: { role: 'STUDENT' } });
        const activeSupervisors = await prisma.user.count({ where: { role: 'SUPERVISOR' } });
        // Students in field — have an active (non-checked-out) FieldSession today
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const studentsInField = await prisma.fieldSession.count({
            where: {
                checkOutTime: null,
                checkInTime: { gte: today },
            },
        });
        // Submissions today (FieldLogs created today, not DRAFT)
        const submittedToday = await prisma.fieldLog.count({
            where: {
                timestamp: { gte: today },
                status: { not: 'DRAFT' },
            },
        });
        // Pending reviews (SUBMITTED, RESUBMITTED, UNDER_REVIEW)
        const pendingReviews = await prisma.fieldLog.count({
            where: {
                status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] },
            },
        });
        // Active projects — count distinct students with at least one field session this year
        const activeProjects = await prisma.fieldSession.groupBy({
            by: ['studentId'],
            _count: { id: true },
            where: { checkInTime: { gte: new Date(new Date().getFullYear(), 0, 1) } },
        });
        // ── Activity Trend (last 7 days) ──
        const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const activityTrend = [];
        for (let i = 6; i >= 0; i--) {
            const dayStart = new Date(today);
            dayStart.setDate(dayStart.getDate() - i);
            const dayEnd = new Date(dayStart);
            dayEnd.setDate(dayEnd.getDate() + 1);
            const count = await prisma.fieldLog.count({
                where: {
                    timestamp: { gte: dayStart, lt: dayEnd },
                    status: { not: 'DRAFT' },
                },
            });
            const dayOfWeek = dayStart.getDay();
            activityTrend.push({
                label: dayLabels[dayOfWeek],
                value: count,
                dateLabel: dayStart.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' }),
            });
        }
        // ── Attendance Trend (last 7 days) ──
        const attendanceTrend = [];
        for (let i = 6; i >= 0; i--) {
            const dayStart = new Date(today);
            dayStart.setDate(dayStart.getDate() - i);
            const dayEnd = new Date(dayStart);
            dayEnd.setDate(dayEnd.getDate() + 1);
            // Unique students with active sessions overlapping the day
            const activeSessionsCount = await prisma.fieldSession.groupBy({
                by: ['studentId'],
                where: {
                    checkInTime: { lt: dayEnd },
                    OR: [
                        { checkOutTime: null },
                        { checkOutTime: { gte: dayStart } },
                    ],
                },
                _count: { id: true },
            });
            const dayOfWeek = dayStart.getDay();
            attendanceTrend.push({
                label: dayLabels[dayOfWeek],
                value: activeSessionsCount.length,
                dateLabel: dayStart.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' }),
            });
        }
        // ── Submission Status Breakdown ──
        const approvedCount = await prisma.fieldLog.count({ where: { status: 'APPROVED' } });
        const pendingStatusCount = await prisma.fieldLog.count({
            where: { status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] } },
        });
        const rejectedCount = await prisma.fieldLog.count({ where: { status: 'REJECTED' } });
        const totalSubmissions = approvedCount + pendingStatusCount + rejectedCount || 1; // avoid div by 0
        const submissionStatus = [
            { label: 'Approved', value: approvedCount, color: '#169B45' },
            { label: 'Pending', value: pendingStatusCount, color: '#FF7A00' },
            { label: 'Rejected', value: rejectedCount, color: '#EF4444' },
        ];
        // ── Department Stats ──
        const deptGroups = await prisma.studentProfile.groupBy({
            by: ['department'],
            _count: { id: true },
            where: { department: { not: null } },
            orderBy: { _count: { id: 'desc' } },
        });
        const maxDeptCount = deptGroups.length > 0 ? Math.max(...deptGroups.map(d => d._count.id)) : 1;
        const deptColors = ['#169B45', '#3B82F6', '#A855F7', '#14B8A6', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'];
        const departmentStats = deptGroups.map((d, i) => ({
            name: d.department ?? 'Unknown',
            count: d._count.id,
            percentage: Math.round((d._count.id / maxDeptCount) * 100) / 100,
            color: deptColors[i % deptColors.length],
        }));
        // ── Recent Users (last 5 created) ──
        const recentUsersData = await prisma.user.findMany({
            take: 5,
            orderBy: { createdAt: 'desc' },
            select: {
                id: true,
                name: true,
                role: true,
                createdAt: true,
            },
        });
        const now = new Date();
        const recentUsers = recentUsersData.map((u) => {
            const diffMs = now.getTime() - u.createdAt.getTime();
            const diffMins = Math.floor(diffMs / 60000);
            let time;
            if (diffMins < 60)
                time = `${diffMins}m ago`;
            else if (diffMins < 1440)
                time = `${Math.floor(diffMins / 60)}h ago`;
            else
                time = `${Math.floor(diffMins / 1440)}d ago`;
            return {
                name: u.name,
                role: u.role === 'STUDENT' ? 'Student' : u.role === 'SUPERVISOR' ? 'Supervisor' : 'Admin',
                time,
                avatarUrl: '',
            };
        });
        // ── System Activities (last 5 audit logs) ──
        const auditLogs = await prisma.auditLog.findMany({
            take: 5,
            orderBy: { timestamp: 'desc' },
            include: { actor: { select: { name: true } } },
        });
        const sysActivityIcons = {
            USER_CREATED: { icon: 'userPlus', color: '#169B45' },
            USER_UPDATED: { icon: 'pencilCircle', color: '#3B82F6' },
            USER_STATUS_UPDATED: { icon: 'toggleLeft', color: '#FF7A00' },
            PASSWORD_RESET: { icon: 'key', color: '#A855F7' },
            USER_ARCHIVED: { icon: 'trash', color: '#EF4444' },
            SUPERVISOR_REASSIGNED: { icon: 'arrowsClockwise', color: '#14B8A6' },
        };
        const systemActivities = auditLogs.map((log) => {
            const meta = sysActivityIcons[log.action] ?? { icon: 'info', color: '#6B7280' };
            const timeStr = log.timestamp.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
            });
            return {
                title: log.action.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
                desc: log.details
                    ? (typeof log.details === 'object' ? JSON.stringify(log.details).substring(0, 60) : String(log.details))
                    : `By ${log.actor?.name ?? 'System'}`,
                time: timeStr,
                icon: meta.icon,
                color: meta.color,
            };
        });
        res.json({
            totalStudents,
            activeSupervisors,
            studentsInField,
            submittedToday,
            pendingReviews,
            activeProjects: activeProjects.length,
            activityTrend,
            attendanceTrend,
            submissionStatus,
            departmentStats,
            recentUsers,
            systemActivities,
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
        let assignedStudentIds = [];
        let supervisor = null;
        if (supervisorId) {
            const supervisorProfile = await prisma.supervisorProfile.findUnique({
                where: { userId: supervisorId },
                include: { assignedStudents: true, user: true }
            });
            if (supervisorProfile) {
                supervisor = {
                    name: supervisorProfile.user.name,
                    avatarUrl: null, // User does not have avatarUrl
                    department: supervisorProfile.department,
                };
                assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
            }
        }
        // Removed testing fallback: Fresh supervisors should see empty stats until students are assigned
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
