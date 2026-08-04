import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
export async function getAdminDashboard(req, res) {
    try {
        const period = req.query.period;
        let periodStart;
        const currentDate = new Date();
        switch (period) {
            case 'Today':
                periodStart = new Date(currentDate.setHours(0, 0, 0, 0));
                break;
            case 'This Week': {
                const d = new Date();
                const day = d.getDay();
                const diff = d.getDate() - day + (day === 0 ? -6 : 1);
                periodStart = new Date(d.setDate(diff));
                periodStart.setHours(0, 0, 0, 0);
                break;
            }
            case 'This Month':
                periodStart = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
                break;
            case 'This Year':
                periodStart = new Date(currentDate.getFullYear(), 0, 1);
                break;
            case 'All Time':
                periodStart = undefined;
                break;
            default: {
                const defaultD = new Date();
                const day = defaultD.getDay();
                const diff = defaultD.getDate() - day + (day === 0 ? -6 : 1);
                periodStart = new Date(defaultD.setDate(diff));
                periodStart.setHours(0, 0, 0, 0);
                break;
            }
        }
        // ── General Stats ──
        const totalStudents = await prisma.user.count({ where: { role: 'STUDENT' } });
        const activeSupervisors = await prisma.user.count({ where: { role: 'SUPERVISOR' } });
        // Students in field — have an active (non-checked-out) FieldSession
        const studentsInField = await prisma.fieldSession.count({
            where: {
                checkOutTime: null,
                ...(periodStart ? { checkInTime: { gte: periodStart } } : {}),
            },
        });
        // Submissions in period (FieldLogs created in period, not DRAFT)
        const submittedToday = await prisma.fieldLog.count({
            where: {
                ...(periodStart ? { timestamp: { gte: periodStart } } : {}),
                status: { not: 'DRAFT' },
            },
        });
        // Pending reviews (SUBMITTED, RESUBMITTED, UNDER_REVIEW)
        const pendingReviews = await prisma.fieldLog.count({
            where: {
                status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] },
            },
        });
        // Active projects — count distinct students with at least one field session in period
        const activeProjects = await prisma.fieldSession.groupBy({
            by: ['studentId'],
            _count: { id: true },
            where: periodStart ? { checkInTime: { gte: periodStart } } : {},
        });
        // ── Dynamic Trend Generation ──
        const activityTrend = [];
        const attendanceTrend = [];
        const intervals = [];
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        if (period === 'This Month') {
            // 4 weeks of the month
            const startOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
            for (let i = 0; i < 4; i++) {
                const wStart = new Date(startOfMonth);
                wStart.setDate(startOfMonth.getDate() + (i * 7));
                const wEnd = new Date(wStart);
                wEnd.setDate(wStart.getDate() + 7);
                intervals.push({
                    start: wStart,
                    end: wEnd,
                    label: `Week ${i + 1}`,
                    dateLabel: `${wStart.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${wEnd.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`,
                });
            }
        }
        else if (period === 'This Year' || period === 'All Time') {
            // 12 months
            for (let i = 0; i < 12; i++) {
                const mStart = new Date(currentDate.getFullYear(), i, 1);
                const mEnd = new Date(currentDate.getFullYear(), i + 1, 1);
                intervals.push({
                    start: mStart,
                    end: mEnd,
                    label: mStart.toLocaleString('default', { month: 'short' }),
                    dateLabel: mStart.toLocaleString('default', { month: 'long', year: 'numeric' }),
                });
            }
        }
        else {
            // 7 days (Today, This Week, default)
            const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
            for (let i = 6; i >= 0; i--) {
                const dStart = new Date(today);
                dStart.setDate(today.getDate() - i);
                const dEnd = new Date(dStart);
                dEnd.setDate(dEnd.getDate() + 1);
                intervals.push({
                    start: dStart,
                    end: dEnd,
                    label: dayLabels[dStart.getDay()],
                    dateLabel: dStart.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' }),
                });
            }
        }
        for (const inv of intervals) {
            // Activity
            const actCount = await prisma.fieldLog.count({
                where: {
                    timestamp: { gte: inv.start, lt: inv.end },
                    status: { not: 'DRAFT' },
                },
            });
            activityTrend.push({ label: inv.label, value: actCount, dateLabel: inv.dateLabel });
            // Attendance
            const activeSessionsCount = await prisma.fieldSession.groupBy({
                by: ['studentId'],
                where: {
                    checkInTime: { lt: inv.end },
                    OR: [
                        { checkOutTime: null },
                        { checkOutTime: { gte: inv.start } },
                    ],
                },
                _count: { id: true },
            });
            attendanceTrend.push({ label: inv.label, value: activeSessionsCount.length, dateLabel: inv.dateLabel });
        }
        // ── Submission Status Breakdown ──
        const approvedCount = await prisma.fieldLog.count({ where: { status: 'APPROVED' } });
        const pendingStatusCount = await prisma.fieldLog.count({
            where: { status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] } },
        });
        const rejectedCount = await prisma.fieldLog.count({ where: { status: 'REJECTED' } });
        const totalSubmissions = approvedCount + pendingStatusCount + rejectedCount || 1; // avoid div by 0
        const submissionStatus = [
            { label: 'Approved', value: approvedCount, color: '#047857' },
            { label: 'Pending', value: pendingStatusCount, color: '#10B981' },
            { label: 'Rejected', value: rejectedCount, color: '#6EE7B7' },
        ];
        // ── Department Stats ──
        const deptGroups = await prisma.studentProfile.groupBy({
            by: ['department'],
            _count: { id: true },
            where: { department: { not: null } },
            orderBy: { _count: { id: 'desc' } },
        });
        const maxDeptCount = deptGroups.length > 0 ? Math.max(...deptGroups.map(d => d._count.id)) : 1;
        const deptColors = ['#059669', '#10B981', '#34D399', '#6EE7B7', '#A7F3D0', '#047857', '#065F46'];
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
                studentProfile: { select: { avatar: true } },
                supervisorProfile: { select: { avatar: true } }
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
                avatarUrl: u.studentProfile?.avatar ?? u.supervisorProfile?.avatar ?? '',
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
                    avatarUrl: supervisorProfile.avatar,
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
            include: {
                user: true,
                evidence: {
                    where: { mimeType: { startsWith: 'image/' } },
                    take: 1,
                    orderBy: { uploadedAt: 'desc' },
                    select: { storagePath: true, thumbnailPath: true },
                },
            }
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
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const profile = await prisma.studentProfile.findUnique({ where: { userId } });
        const totalActivities = await prisma.fieldLog.count({ where: { studentId: userId } });
        const evidenceFiles = await prisma.evidence.count({ where: { log: { studentId: userId } } });
        res.json({
            status: profile?.status ?? 'IDLE',
            totalActivities,
            evidenceFiles,
            syncStatus: 'Synced',
            // Legacy fields
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
