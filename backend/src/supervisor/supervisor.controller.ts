import { Request, Response } from 'express';
import { prisma } from '../db.js';
import { ReportService } from '../reports/report.service.js';

// ── GET /api/v1/supervisor/dashboard/stats
export const getDashboardStats = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId }
    });

    if (!supervisorProfile) {
      res.json({ checkedOut: 0, checkedIn: 0, inField: 0 });
      return;
    }

    const students = await prisma.user.findMany({
      where: {
        role: 'STUDENT',
        studentProfile: { supervisorId: supervisorProfile.id },
      },
      include: {
        fieldSessions: {
          where: { checkOutTime: null }
        }
      }
    });

    let checkedIn = 0;
    let checkedOut = 0;
    let inField = 0;

    for (const s of students) {
      if (s.fieldSessions && s.fieldSessions.length > 0) {
        checkedIn++;
        inField++;
      } else {
        checkedOut++;
      }
    }

    res.json({ checkedOut, checkedIn, inField });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students
export const getStudents = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId }
    });

    if (!supervisorProfile) {
      res.json([]);
      return;
    }

    const students = await prisma.user.findMany({
      where: {
        role: 'STUDENT',
        studentProfile: { supervisorId: supervisorProfile.id },
      },
      include: {
        studentProfile: {
          include: {
            supervisor: {
              include: { user: true }
            }
          }
        },
        fieldSessions: {
          where: { checkOutTime: null },
          orderBy: { checkInTime: 'desc' },
          take: 1,
        },
        logs: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        }
      },
      orderBy: { createdAt: 'desc' },
    });

    const mapped = students.map((u) => {
      const sp = u.studentProfile;
      const activeSession = (u as any).fieldSessions?.[0] ?? null;
      const latestLog = (u as any).logs?.[0] ?? null;
      const supervisorUser = sp?.supervisor?.user;

      const isCheckedIn = !!activeSession;
      const fieldStatus = isCheckedIn ? 'In Field' : 'Offline';
      const lastActivity = latestLog?.timestamp
        ? new Date(latestLog.timestamp).toISOString()
        : null;

      return {
        id: u.id,
        name: u.name,
        email: u.email,
        status: u.status,
        avatarUrl: sp?.avatar ?? '',
        reg: sp?.registrationNo ?? '',
        programme: sp?.programme ?? '',
        department: sp?.department ?? '',
        faculty: sp?.faculty ?? '',
        topic: sp?.topic ?? '',
        checkInStatus: isCheckedIn ? 'Checked In' : 'Checked Out',
        fieldStatus,
        lastActivity,
        supervisorId: sp?.supervisorId ?? null,
        supervisorName: supervisorUser?.name ?? null,
        currentSession: activeSession
          ? {
              active: true,
              checkInTime: activeSession.checkInTime.toISOString(),
              checkOutTime: activeSession.checkOutTime?.toISOString() ?? null,
              latitude: activeSession.startLatitude ?? 0,
              longitude: activeSession.startLongitude ?? 0,
              accuracy: activeSession.startAccuracy ?? 0,
            }
          : null,
      };
    });

    res.json(mapped);
  } catch (error) {
    console.error('Supervisor students error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id
export const getStudentById = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    const u = await prisma.user.findUnique({
      where: { id },
      include: {
        studentProfile: {
          include: {
            supervisor: { include: { user: true } }
          }
        },
        fieldSessions: {
          orderBy: { checkInTime: 'desc' },
          take: 10,
        },
        logs: {
          orderBy: { timestamp: 'desc' },
          take: 20,
          include: { evidence: true, reviews: true }
        },
      }
    });

    if (!u) {
      res.status(404).json({ error: 'Student not found' });
      return;
    }

    const sp = u.studentProfile;
    const sessions = (u as any).fieldSessions ?? [];
    const activeSession = sessions.find((s: any) => !s.checkOutTime) ?? null;
    const isCheckedIn = !!activeSession;
    const logs = (u as any).logs ?? [];
    const supervisorUser = sp?.supervisor?.user;

    res.json({
      id: u.id,
      name: u.name,
      email: u.email,
      status: u.status,
      avatarUrl: sp?.avatar ?? '',
      reg: sp?.registrationNo ?? '',
      programme: sp?.programme ?? '',
      department: sp?.department ?? '',
      faculty: sp?.faculty ?? '',
      phone: sp?.phone ?? '',
      topic: sp?.topic ?? '',
      university: sp?.faculty ?? '',
      checkInStatus: isCheckedIn ? 'Checked In' : 'Checked Out',
      fieldStatus: isCheckedIn ? 'In Field' : 'Offline',
      lastActivity: logs[0]?.timestamp ?? null,
      supervisorId: sp?.supervisorId ?? null,
      supervisorName: supervisorUser?.name ?? null,
      supervisorEmail: supervisorUser?.email ?? null,
      currentSession: activeSession
        ? {
            active: true,
            checkInTime: activeSession.checkInTime.toISOString(),
            checkOutTime: activeSession.checkOutTime?.toISOString() ?? null,
            latitude: activeSession.startLatitude ?? 0,
            longitude: activeSession.startLongitude ?? 0,
            accuracy: activeSession.startAccuracy ?? 0,
          }
        : null,
      activities: logs.map((l: any) => ({
        id: l.id,
        title: l.title,
        description: l.description ?? '',
        status: l.status,
        startTime: l.timestamp.toISOString(),
        endTime: l.timestamp.toISOString(),
        duration: 0,
        category: '',
        methodology: l.methodology ?? '',
        objectives: l.objectives ?? '',
        findings: l.findings ?? '',
        remarks: l.remarks ?? '',
        location: {
          latitude: l.latitude ?? 0,
          longitude: l.longitude ?? 0,
          accuracy: l.gpsAccuracy ?? 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          capturedAt: l.timestamp.toISOString(),
          address: '',
        },
        evidence: (l.evidence ?? []).map((e: any) => ({
          id: e.id,
          type: e.type?.toLowerCase() ?? 'image',
          fileName: e.fileName ?? '',
          url: e.url ?? '',
          sizeMB: 0,
          uploadedAt: e.createdAt?.toISOString() ?? new Date().toISOString(),
          uploadedBy: u.name,
        })),
        review: (l.reviews && l.reviews.length > 0) ? l.reviews[0] : null,
      })),
      statistics: {
        totalFieldDays: sessions.length,
        totalActivities: logs.length,
        totalReports: logs.length,
        totalEvidence: logs.reduce((acc: number, l: any) => acc + (l.evidence?.length ?? 0), 0),
        totalImages: logs.reduce((acc: number, l: any) => acc + (l.evidence?.filter((e: any) => e.mimeType?.startsWith('image/')).length ?? 0), 0),
        totalVideos: logs.reduce((acc: number, l: any) => acc + (l.evidence?.filter((e: any) => e.mimeType?.startsWith('video/')).length ?? 0), 0),
        totalDocuments: logs.reduce((acc: number, l: any) => acc + (l.evidence?.filter((e: any) => e.mimeType?.startsWith('application/') || e.mimeType?.startsWith('text/')).length ?? 0), 0),
        totalDistanceTravelled: sessions.reduce((acc: number, s: any) => acc + (s.distanceTravelled ?? 0), 0),
        totalTimeInField: sessions.reduce((acc: number, s: any) => acc + (s.durationSeconds ?? 0), 0),
        firstCheckIn: sessions.length > 0 ? sessions[sessions.length - 1].checkInTime.toISOString() : new Date().toISOString(),
        lastCheckOut: sessions.length > 0 && sessions[0].checkOutTime ? sessions[0].checkOutTime.toISOString() : new Date().toISOString(),
        averageGPSAccuracy: sessions.length > 0 ? sessions.reduce((acc: number, s: any) => acc + (s.averageAccuracy ?? 0), 0) / sessions.length : 0,
      },
      timeline: [
        ...sessions.map((s: any) => ({
          time: s.checkInTime.toISOString(),
          type: 'checkIn',
          title: 'Checked In',
          description: `Checked in (Accuracy: ${s.startAccuracy}m)`
        })),
        ...sessions.filter((s: any) => s.checkOutTime).map((s: any) => ({
          time: s.checkOutTime.toISOString(),
          type: 'checkOut',
          title: 'Checked Out',
          description: `Checked out`
        })),
        ...logs.map((l: any) => {
          const imageEvidence = l.evidence?.find((e: any) => e.mimeType?.startsWith('image/'));
          return {
            time: l.timestamp.toISOString(),
            type: 'activitySubmit',
            title: l.title,
            description: `Activity submitted with ${l.evidence?.length ?? 0} evidence files`,
            imageUrl: imageEvidence?.storagePath || undefined,
            activityId: l.id
          };
        })
      ].sort((a: any, b: any) => new Date(b.time).getTime() - new Date(a.time).getTime()),
    });
  } catch (error) {
    console.error('Get student by ID error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/dashboard/recent-activities
export const getDashboardRecentActivities = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });

    if (!supervisorProfile) {
      res.json([]);
      return;
    }

    const assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
    
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const skip = (page - 1) * limit;

    const recentLogs = await prisma.fieldLog.findMany({
      where: { 
        studentId: { in: assignedStudentIds },
        status: { not: 'DRAFT' }
      },
      take: limit,
      skip: skip,
      orderBy: { timestamp: 'desc' },
      include: {
        user: { include: { studentProfile: true } },
        evidence: {
          where: { mimeType: { startsWith: 'image/' } },
          take: 1,
          orderBy: { uploadedAt: 'desc' },
          select: { storagePath: true, thumbnailPath: true },
        },
      }
    });

    const mapped = recentLogs.map((l: any) => ({
      id: l.id,
      title: l.title,
      timestamp: l.timestamp.toISOString(),
      studentId: l.studentId,
      user: {
        name: l.user.name,
        avatarUrl: l.user.studentProfile?.avatar ?? '',
      },
      evidence: l.evidence
    }));

    res.json(mapped);
  } catch (error) {
    console.error('getDashboardRecentActivities Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/dashboard/feed
export const getDashboardFeed = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });

    if (!supervisorProfile) {
      res.json([]);
      return;
    }

    const assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
    
    const logs = await prisma.fieldLog.findMany({
      where: { studentId: { in: assignedStudentIds }, status: { not: 'DRAFT' } },
      take: 10,
      orderBy: { timestamp: 'desc' },
      include: { user: true }
    });

    const sessions = await prisma.fieldSession.findMany({
      where: { studentId: { in: assignedStudentIds } },
      take: 10,
      orderBy: { checkInTime: 'desc' },
      include: { user: true }
    });
    
    const feed = [
      ...logs.map(l => ({
        time: l.timestamp.toISOString(),
        content: `${l.user.name} submitted an activity: ${l.title}`
      })),
      ...sessions.map(s => ({
        time: s.checkInTime.toISOString(),
        content: `${s.user.name} checked in from the field`
      }))
    ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, 20);

    res.json(feed);
  } catch (error) {
    console.error('getDashboardFeed Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/dashboard/pending-reviews
export const getDashboardPendingReviews = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });

    if (!supervisorProfile) {
      res.json([]);
      return;
    }

    const assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
    
    const logs = await prisma.fieldLog.findMany({
      where: { 
        studentId: { in: assignedStudentIds },
        status: { in: ['SUBMITTED', 'RESUBMITTED', 'UNDER_REVIEW'] }
      },
      orderBy: { timestamp: 'asc' },
      include: { user: true }
    });

    // Format matches RecentActivity / paginated activities logic
    const mapped = logs.map(l => ({
      activityId: l.id,
      title: l.title,
      time: l.timestamp.toISOString(),
      studentId: l.studentId,
      studentName: l.user.name,
      location: 'Pending Review',
      imageUrl: ''
    }));

    res.json(mapped);
  } catch (error) {
    console.error('getDashboardPendingReviews Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/activities
export const getStudentActivities = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.params.id as string;
    
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 50;
    const skip = (page - 1) * limit;

    // For now we will just return logs. FieldActivity vs DailyFieldLog terminology might be mixed here.
    const logs = await prisma.fieldLog.findMany({
      where: { studentId },
      take: limit,
      skip: skip,
      orderBy: { timestamp: 'desc' },
      include: { evidence: true, reviews: true, user: true }
    });
    
    // Map to FieldActivity JSON format as expected by frontend
    const mapped = logs.map(l => ({
      id: l.id,
      title: l.title,
      description: l.description ?? '',
      status: l.status,
      startTime: l.timestamp.toISOString(),
      endTime: l.timestamp.toISOString(),
      duration: 0,
      category: '',
      methodology: l.methodology ?? '',
      objectives: l.objectives ?? '',
      findings: l.findings ?? '',
      remarks: l.remarks ?? '',
      location: {
        latitude: l.latitude ?? 0,
        longitude: l.longitude ?? 0,
        accuracy: l.gpsAccuracy ?? 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        capturedAt: l.timestamp.toISOString(),
        address: '',
      },
      evidence: (l.evidence ?? []).map((e: any) => ({
        id: e.id,
        type: e.mimeType?.startsWith('video') ? 'video' : 'image',
        fileName: e.originalName ?? '',
        url: e.storagePath ?? '',
        sizeMB: (e.fileSize ?? 0) / (1024 * 1024),
        uploadedAt: e.uploadedAt?.toISOString() ?? new Date().toISOString(),
        uploadedBy: l.user?.name ?? 'Student',
      })),
      review: (l.reviews && l.reviews.length > 0) ? l.reviews[0] : null,
    }));
    
    res.json(mapped);
  } catch (error) {
    console.error('getStudentActivities Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/activities/:activityId
export const getStudentActivityById = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.params.id as string;
    const activityId = req.params.activityId as string;
    
    const l = await prisma.fieldLog.findUnique({
      where: { id: activityId },
      include: { evidence: true }
    });
    
    if (!l) {
      res.status(404).json({ error: 'Activity not found' });
      return;
    }
    
    const mapped = {
      id: l.id,
      title: l.title,
      description: l.description ?? '',
      status: l.status,
      startTime: l.timestamp.toISOString(),
      endTime: l.timestamp.toISOString(),
      duration: 0,
      category: '',
      methodology: l.methodology ?? '',
      objectives: l.objectives ?? '',
      findings: l.findings ?? '',
      remarks: l.remarks ?? '',
      location: {
        latitude: l.latitude ?? 0,
        longitude: l.longitude ?? 0,
        accuracy: l.gpsAccuracy ?? 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        capturedAt: l.timestamp.toISOString(),
        address: '',
      },
      evidence: (l.evidence ?? []).map((e: any) => ({
        id: e.id,
        type: e.mimeType?.startsWith('video') ? 'video' : 'image',
        fileName: e.originalName ?? '',
        url: e.storagePath ?? '',
        sizeMB: (e.fileSize ?? 0) / (1024 * 1024),
        uploadedAt: e.uploadedAt?.toISOString() ?? new Date().toISOString(),
        uploadedBy: 'Student',
      })),
      review: null,
    };
    
    res.json(mapped);
  } catch (error) {
    console.error('getStudentActivityById Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/logs
export const getStudentDailyLogs = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.params.id as string;
    const logs = await prisma.fieldLog.findMany({
      where: { studentId },
      orderBy: { timestamp: 'desc' },
      include: { evidence: true }
    });
    
    // Convert to DailyFieldLog format
    const mapped = logs.map(l => ({
      id: l.id,
      date: l.timestamp.toISOString(),
      title: l.title,
      summary: l.description ?? '',
      status: l.status,
      activities: [],
      issues: [],
      nextSteps: '',
      supervisorComments: '',
      evidenceFiles: l.evidence.length,
    }));
    
    res.json(mapped);
  } catch (error) {
    console.error('getStudentDailyLogs Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/activities/:activityId/evidence
export const getStudentActivityEvidence = async (req: Request, res: Response): Promise<void> => {
  try {
    const activityId = req.params.activityId as string;
    const evidence = await prisma.evidence.findMany({
      where: { activityId }
    });
    
    const mapped = evidence.map(e => ({
      id: e.id,
      type: e.mimeType?.startsWith('video') ? 'video' : 'image',
      fileName: e.originalName ?? '',
      url: e.storagePath ?? '',
      sizeMB: (e.fileSize ?? 0) / (1024 * 1024),
      uploadedAt: e.uploadedAt?.toISOString() ?? new Date().toISOString(),
      uploadedBy: 'Student',
    }));
    
    res.json(mapped);
  } catch (error) {
    console.error('getStudentActivityEvidence Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/location
export const getStudentLocation = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.params.id as string;
    const session = await prisma.fieldSession.findFirst({
      where: { studentId, status: 'ACTIVE' },
      orderBy: { checkInTime: 'desc' }
    });
    
    if (!session) {
      res.status(404).json({ error: 'No active session' });
      return;
    }
    
    res.json({
      active: true,
      checkInTime: session.checkInTime.toISOString(),
      checkOutTime: session.checkOutTime?.toISOString() ?? null,
      latitude: session.startLatitude ?? 0,
      longitude: session.startLongitude ?? 0,
      accuracy: session.startAccuracy ?? 0,
    });
  } catch (error) {
    console.error('getStudentLocation Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/timeline
export const getStudentTimeline = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.params.id as string;
    
    const sessions = await prisma.fieldSession.findMany({
      where: { studentId },
      orderBy: { checkInTime: 'desc' },
      take: 20
    });
    
    const logs = await prisma.fieldLog.findMany({
      where: { studentId },
      orderBy: { timestamp: 'desc' },
      take: 20,
      include: { evidence: true }
    });
    
    const timeline = [
      ...sessions.map((s: any) => ({
        time: s.checkInTime.toISOString(),
        type: 'checkIn',
        title: 'Checked In',
        description: `Checked in (Accuracy: ${s.startAccuracy}m)`
      })),
      ...sessions.filter((s: any) => s.checkOutTime).map((s: any) => ({
        time: s.checkOutTime.toISOString(),
        type: 'checkOut',
        title: 'Checked Out',
        description: `Checked out`
      })),
      ...logs.map((l: any) => {
        const imageEvidence = l.evidence?.find((e: any) => e.mimeType?.startsWith('image/'));
        return {
          time: l.timestamp.toISOString(),
          type: 'activitySubmit',
          title: l.title,
          description: `Activity submitted with ${l.evidence?.length ?? 0} evidence files`,
          imageUrl: imageEvidence?.storagePath || undefined,
          activityId: l.id
        };
      })
    ].sort((a: any, b: any) => new Date(b.time).getTime() - new Date(a.time).getTime());
    
    res.json(timeline);
  } catch (error) {
    console.error('getStudentTimeline Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/students/:id/notifications
export const getStudentNotifications = async (req: Request, res: Response): Promise<void> => {
  try {
    const studentId = req.params.id as string;
    
    const notifications = await prisma.notification.findMany({
      where: { recipientId: studentId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    
    res.json(notifications);
  } catch (error) {
    console.error('getStudentNotifications Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/map/live
export const getLiveMapLocations = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });

    if (!supervisorProfile) {
      res.json([]);
      return;
    }

    const assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
    
    // Get all active sessions for map
    const activeSessions = await prisma.fieldSession.findMany({
      where: { studentId: { in: assignedStudentIds }, status: 'ACTIVE' },
      include: { user: true }
    });
    
    const mapped = activeSessions.map(s => ({
      studentId: s.studentId,
      studentName: s.user.name,
      latitude: s.startLatitude ?? 0,
      longitude: s.startLongitude ?? 0,
      accuracy: s.startAccuracy ?? 0,
      checkInTime: s.checkInTime.toISOString(),
    }));

    res.json(mapped);
  } catch (error) {
    console.error('getLiveMapLocations Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── POST /api/v1/supervisor/reports/generate
export const generateReport = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    if (!supervisorId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { type } = req.body; // e.g. 'pdf' or 'csv'
    
    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });
    
    if (!supervisorProfile) {
      res.status(404).json({ error: 'Supervisor profile not found' });
      return;
    }

    const assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
    
    // For this example, we generate a report of the last 100 activities
    const logs = await prisma.fieldLog.findMany({
      where: { studentId: { in: assignedStudentIds } },
      take: 100,
      orderBy: { timestamp: 'desc' },
      include: { user: true }
    });

    if (type === 'csv') {
      const csvString = ReportService.generateCSV(logs);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="supervisor_report.csv"');
      res.send(csvString);
    } else {
      // Default to PDF
      const pdfBuffer = await ReportService.generatePDF(logs, 'FieldTrack Supervisor Report');
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="supervisor_report.pdf"');
      res.send(pdfBuffer);
    }
  } catch (error) {
    console.error('generateReport Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

// ── GET /api/v1/supervisor/logs/export
export const exportLogs = async (req: Request, res: Response): Promise<void> => {
  try {
    const supervisorId = req.user?.userId;
    if (!supervisorId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const supervisorProfile = await prisma.supervisorProfile.findUnique({
      where: { userId: supervisorId },
      include: { assignedStudents: true }
    });
    
    if (!supervisorProfile) {
      res.status(404).json({ error: 'Supervisor profile not found' });
      return;
    }

    const assignedStudentIds = supervisorProfile.assignedStudents.map(s => s.userId);
    
    const logs = await prisma.fieldLog.findMany({
      where: { studentId: { in: assignedStudentIds } },
      orderBy: { timestamp: 'desc' },
      include: { user: true }
    });

    const csvString = ReportService.generateCSV(logs);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="field_logs.csv"');
    res.send(csvString);
  } catch (error) {
    console.error('exportLogs Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};
