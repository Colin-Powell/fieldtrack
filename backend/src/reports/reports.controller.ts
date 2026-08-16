import { Request, Response } from 'express';
import { prisma } from '../db.js';

function getPeriodStart(period: string): Date | undefined {
  const now = new Date();
  switch (period) {
    case 'This Week': {
      const d = new Date(now);
      const day = d.getDay();
      const diff = d.getDate() - day + (day === 0 ? -6 : 1);
      d.setDate(diff);
      d.setHours(0, 0, 0, 0);
      return d;
    }
    case 'This Month': {
      return new Date(now.getFullYear(), now.getMonth(), 1);
    }
    case 'This Quarter': {
      const quarterStartMonth = Math.floor(now.getMonth() / 3) * 3;
      return new Date(now.getFullYear(), quarterStartMonth, 1);
    }
    case 'This Year': {
      return new Date(now.getFullYear(), 0, 1);
    }
    default:
      return undefined; // All time
  }
}

function buildTrendIntervals(period: string): { start: Date; end: Date; label: string; dateLabel: string }[] {
  const intervals: { start: Date; end: Date; label: string; dateLabel: string }[] = [];
  const now = new Date();
  now.setHours(0, 0, 0, 0);

  if (period === 'This Year') {
    // 12 months
    for (let i = 0; i < 12; i++) {
      const mStart = new Date(now.getFullYear(), i, 1);
      const mEnd = new Date(now.getFullYear(), i + 1, 1);
      intervals.push({
        start: mStart,
        end: mEnd,
        label: mStart.toLocaleString('default', { month: 'short' }),
        dateLabel: mStart.toLocaleString('default', { month: 'long', year: 'numeric' }),
      });
    }
  } else if (period === 'This Quarter') {
    // 3 months of the quarter
    const quarterStartMonth = Math.floor(now.getMonth() / 3) * 3;
    for (let i = 0; i < 3; i++) {
      const mStart = new Date(now.getFullYear(), quarterStartMonth + i, 1);
      const mEnd = new Date(now.getFullYear(), quarterStartMonth + i + 1, 1);
      intervals.push({
        start: mStart,
        end: mEnd,
        label: mStart.toLocaleString('default', { month: 'short' }),
        dateLabel: mStart.toLocaleString('default', { month: 'long', year: 'numeric' }),
      });
    }
  } else if (period === 'This Month') {
    // 4 weeks of the month
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
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
  } else {
    // 7 days (This Week and default)
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (let i = 6; i >= 0; i--) {
      const dStart = new Date(now);
      dStart.setDate(now.getDate() - i);
      dStart.setHours(0, 0, 0, 0);
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

  return intervals;
}

export async function getSupervisorReports(req: Request, res: Response) {
  try {
    const supervisorId = req.user?.userId;
    if (!supervisorId) return res.status(401).json({ error: 'Unauthorized' });

    const period = (req.query.period as string) || 'This Month';
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);
    const offset = parseInt(req.query.offset as string) || 0;
    const periodStart = getPeriodStart(period);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Find assigned students
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });

    const assignedStudentIds = supervisorProfile?.assignedStudents.map(s => s.userId) || [];

    // Build date filter for queries
    const dateFilter = periodStart ? { timestamp: { gte: periodStart } } : {};

    // Fetch logs for assigned students within period
    const allLogs = await prisma.fieldLog.findMany({
      where: {
        studentId: { in: assignedStudentIds },
        ...dateFilter,
      },
      include: { user: true }
    });

    const totalActivities = allLogs.length;
    
    // Count activities submitted (including those approved/resubmitted)
    const reportsSubmitted = allLogs.filter(l => ['SUBMITTED', 'APPROVED', 'RESUBMITTED'].includes(l.status)).length;
    
    // Pending reviews (just submitted/resubmitted)
    const pendingReviews = allLogs.filter(l => ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'].includes(l.status)).length;
    
    // Approved logs
    const approvedLogs = allLogs.filter(l => l.status === 'APPROVED').length;

    // Build trend intervals based on period
    const intervals = buildTrendIntervals(period);

    // Calculate trend data for each interval
    const trendDataPoints: { label: string; dateLabel: string; value: number }[] = [];
    for (const inv of intervals) {
      const count = await prisma.fieldLog.count({
        where: {
          studentId: { in: assignedStudentIds },
          timestamp: { gte: inv.start, lt: inv.end },
        },
      });
      trendDataPoints.push({ label: inv.label, value: count, dateLabel: inv.dateLabel });
    }

    // Gauge Distribution (by methodology)
    const methodologyDistribution: Record<string, number> = {};
    let countWithMethodology = 0;

    allLogs.forEach(log => {
      if (log.methodology) {
        methodologyDistribution[log.methodology] = (methodologyDistribution[log.methodology] || 0) + 1;
        countWithMethodology++;
      }
    });

    // Normalize gauge to percentages (0.0 to 1.0)
    const gaugeMap: Record<string, number> = {};
    if (countWithMethodology > 0) {
      for (const [key, val] of Object.entries(methodologyDistribution)) {
        gaugeMap[key] = val / countWithMethodology;
      }
    } else {
      // Default placeholder if no data
      gaugeMap['Field Survey'] = 0.0;
    }

    // Recent activities feed
    const recentActivities = allLogs
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(0, 10)
      .map(log => {
        const timeStr = log.timestamp.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        return {
          id: log.id,
          studentName: log.user.name,
          activityTitle: log.title,
          time: timeStr,
          status: log.status,
        };
      });

    // Log summary for the export
    const logSummary = allLogs
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .map(log => ({
        title: log.title,
        student: log.user.name,
        status: log.status,
        timestamp: log.timestamp.toISOString(),
        methodology: log.methodology || '',
      }));

    const paginatedLogs = recentActivities.slice(offset, offset + limit);

    res.json({
      stats: {
        totalActivities,
        reportsSubmitted,
        pendingReviews,
        approvedLogs,
      },
      gaugeMap,
      trendData: trendDataPoints,
      recentActivities: paginatedLogs,
      total: recentActivities.length,
      limit,
      offset,
      logSummary,
      period,
      periodStart: periodStart?.toISOString() || null,
    });
  } catch (error) {
    console.error('getSupervisorReports error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getAdminReports(req: Request, res: Response) {
  try {
    const period = (req.query.period as string) || 'This Month';
    const department = req.query.department as string | undefined;
    const supervisorId = req.query.supervisorId as string | undefined;
    const county = req.query.county as string | undefined;
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);
    const offset = parseInt(req.query.offset as string) || 0;

    const periodStart = getPeriodStart(period);

    const dateFilter = periodStart ? { timestamp: { gte: periodStart } } : {};
    const deptFilter = department && department !== 'All Departments' ? { user: { studentProfile: { department } } } : {};
    const supFilter = supervisorId && supervisorId !== 'All Supervisors' ? { user: { studentProfile: { supervisorId } } } : {};
    const countyFilter = county && county !== 'All Counties' ? { county } : {}; // Requires county field if exists, else skip.

    // Let's gather all logs matching the criteria
    const allLogs = await prisma.fieldLog.findMany({
      where: {
        ...dateFilter,
        ...deptFilter,
        ...supFilter,
        // Since fieldLog doesn't have county directly, if location exists it might be in `location` field, but we'll mock county distribution for now based on location string or skip filter if not directly mapped.
      },
      include: { user: { include: { studentProfile: { include: { supervisor: { include: { user: true } } } } } } }
    });

    const totalActivities = allLogs.length;

    // Build trend intervals based on period
    const intervals = buildTrendIntervals(period);
    const trendDataPoints: { label: string; dateLabel: string; value: number }[] = [];
    for (const inv of intervals) {
      const count = allLogs.filter(l => l.timestamp >= inv.start && l.timestamp < inv.end).length;
      trendDataPoints.push({ label: inv.label, value: count, dateLabel: inv.dateLabel });
    }

    // Real County Distribution
    const countyDistribution: Record<string, number> = {};
    allLogs.forEach(log => {
      const county = log.county || 'Unknown';
      countyDistribution[county] = (countyDistribution[county] || 0) + 1;
    });

    // Filters for dropdowns
    const departments = await prisma.department.findMany({ select: { name: true } }).then(d => d.map(x => x.name));
    const supervisors = await prisma.user.findMany({ where: { role: 'SUPERVISOR' }, select: { id: true, name: true } });

    const logSummaryAll = allLogs.map(l => ({
      title: l.title,
      student: l.user.name,
      department: l.user.studentProfile?.department || 'N/A',
      supervisor: l.user.studentProfile?.supervisor?.user.name || 'N/A',
      status: l.status,
      timestamp: l.timestamp.toISOString(),
      location: l.locationName || 'Unknown',
      county: l.county || 'Unknown',
    }));

    res.json({
      stats: { totalActivities },
      trendData: trendDataPoints,
      countyDistribution,
      filters: {
        departments: ['All Departments', ...departments],
        supervisors: [{ id: 'All Supervisors', name: 'All Supervisors' }, ...supervisors.map(s => ({ id: s.id, name: s.name }))],
        counties: ['All Counties', 'Nairobi', 'Mombasa', 'Kisumu', 'Other'],
      },
      logSummary: logSummaryAll.slice(offset, offset + limit),
      total: logSummaryAll.length,
      limit,
      offset,
    });
  } catch (error) {
    console.error('getAdminReports error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
