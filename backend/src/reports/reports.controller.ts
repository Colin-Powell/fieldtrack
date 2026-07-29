import { Request, Response } from 'express';
import { prisma } from '../db.js';

export async function getSupervisorReports(req: Request, res: Response) {
  try {
    const supervisorId = req.user?.userId;
    if (!supervisorId) return res.status(401).json({ error: 'Unauthorized' });

    // Find assigned students
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });

    const assignedStudentIds = supervisorProfile?.assignedStudents.map(s => s.userId) || [];

    // Initialize stats
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    // Fetch all logs for assigned students
    const allLogs = await prisma.fieldLog.findMany({
      where: { studentId: { in: assignedStudentIds } },
      include: { user: true }
    });

    const totalActivities = allLogs.length;
    
    // Count activities submitted (including those approved/resubmitted)
    const reportsSubmitted = allLogs.filter(l => ['SUBMITTED', 'APPROVED', 'RESUBMITTED'].includes(l.status)).length;
    
    // Pending reviews (just submitted/resubmitted)
    const pendingReviews = allLogs.filter(l => ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'].includes(l.status)).length;
    
    // Approved logs
    const approvedLogs = allLogs.filter(l => l.status === 'APPROVED').length;

    // Trend calculation (last 30 days)
    const trendData: Record<string, number> = {};
    for (let i = 29; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      d.setHours(0, 0, 0, 0);
      const label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      trendData[label] = 0;
    }

    // Gauge Distribution (by methodology)
    const methodologyDistribution: Record<string, number> = {};
    let countWithMethodology = 0;

    allLogs.forEach(log => {
      // populate trend
      const d = new Date(log.timestamp);
      d.setHours(0, 0, 0, 0);
      const label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      if (trendData[label] !== undefined) {
        trendData[label]++;
      }

      // populate gauge
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
      gaugeMap['Field Survey'] = 0.5;
      gaugeMap['Lab Work'] = 0.5;
    }

    // Convert trend to array format expected by frontend
    const trendArray = Object.entries(trendData).map(([label, value]) => ({
      label: label.split(' ')[1], // just the day number for x-axis if needed
      dateLabel: label + ', ' + today.getFullYear(),
      value
    }));

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

    res.json({
      stats: {
        totalActivities,
        reportsSubmitted,
        pendingReviews,
        approvedLogs,
      },
      gaugeMap,
      trendData: trendArray,
      recentActivities,
    });
  } catch (error) {
    console.error('getSupervisorReports error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
