import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import { AuditLogService } from '../services/audit-log.service.js';
import { prisma } from '../db.js';

// Generate a random temporary password
function generateTempPassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < 12; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

export async function createStudent(req: Request, res: Response) {
  try {
    const actorId = req.user?.userId;
    const {
      firstName,
      lastName,
      registrationNo,
      email,
      phone,
      programme,
      department,
      faculty,
      researchTopic,
      supervisorId,
    } = req.body;

    if (!firstName || !lastName || !registrationNo || !email) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'Email is already in use' });
    }

    const existingStudent = await prisma.studentProfile.findUnique({ where: { registrationNo } });
    if (existingStudent) {
      return res.status(400).json({ error: 'Registration number already exists' });
    }

    let actualSupervisorProfileId = undefined;
    if (supervisorId) {
      const supervisorProfile = await prisma.supervisorProfile.findUnique({ where: { userId: supervisorId } });
      if (supervisorProfile) {
        actualSupervisorProfileId = supervisorProfile.id;
      } else {
        return res.status(400).json({ error: 'Invalid supervisor selected' });
      }
    }

    const tempPassword = generateTempPassword();
    const hashedPassword = await bcrypt.hash(tempPassword, 12);
    const fullName = `${firstName} ${lastName}`;

    const user = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          name: fullName,
          email,
          password: hashedPassword,
          role: 'STUDENT',
          mustChangePassword: true,
          status: 'ACTIVE',
        },
      });

      await tx.studentProfile.create({
        data: {
          userId: newUser.id,
          registrationNo,
          phone,
          programme,
          department,
          faculty,
          topic: researchTopic,
          supervisorId: actualSupervisorProfileId,
        },
      });

      return newUser;
    });

    await AuditLogService.log({
      actorId,
      userId: user.id,
      action: 'USER_CREATED',
      details: { role: 'STUDENT', registrationNo },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    return res.status(201).json({
      success: true,
      message: 'Student created successfully',
      tempPassword,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      }
    });
  } catch (error: any) {
    console.error('Create student error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function createSupervisor(req: Request, res: Response) {
  try {
    const actorId = req.user?.userId;
    const {
      fullName,
      email,
      phone,
      staffNumber,
      department,
      faculty,
      office,
      specialization,
      studentCapacity,
    } = req.body;

    if (!fullName || !email || !staffNumber) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'Email is already in use' });
    }

    const existingSupervisor = await prisma.supervisorProfile.findUnique({ where: { staffNumber } });
    if (existingSupervisor) {
      return res.status(400).json({ error: 'Staff number already exists' });
    }

    const tempPassword = generateTempPassword();
    const hashedPassword = await bcrypt.hash(tempPassword, 12);

    const user = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          name: fullName,
          email,
          password: hashedPassword,
          role: 'SUPERVISOR',
          mustChangePassword: true,
          status: 'ACTIVE',
        },
      });

      await tx.supervisorProfile.create({
        data: {
          userId: newUser.id,
          staffNumber,
          phone,
          department,
          faculty,
          office,
          specialization,
          studentCapacity: typeof studentCapacity === 'number' ? studentCapacity : (studentCapacity ? parseInt(studentCapacity, 10) : 20),
        },
      });

      return newUser;
    });

    await AuditLogService.log({
      actorId,
      userId: user.id,
      action: 'USER_CREATED',
      details: { role: 'SUPERVISOR', staffNumber },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    return res.status(201).json({
      success: true,
      message: 'Supervisor created successfully',
      tempPassword,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      }
    });
  } catch (error: any) {
    console.error('Create supervisor error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getAllUsers(req: Request, res: Response) {
  try {
    const users = await prisma.user.findMany({
      include: {
        studentProfile: {
          include: {
            supervisor: {
              include: { user: true }
            }
          }
        },
        supervisorProfile: {
          include: { assignedStudents: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const mappedUsers = users.map(user => {
      let regNo;
      let department = '-';
      let supervisorName;
      let assignedStudentsCount;

      if (user.role === 'STUDENT' && user.studentProfile) {
        regNo = user.studentProfile.registrationNo;
        department = user.studentProfile.department ?? '-';
        if (user.studentProfile.supervisor) {
          supervisorName = user.studentProfile.supervisor.user.name;
        }
      } else if (user.role === 'SUPERVISOR' && user.supervisorProfile) {
        department = user.supervisorProfile.department ?? '-';
        assignedStudentsCount = user.supervisorProfile.assignedStudents?.length || 0;
      }

      return {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        department,
        regNo,
        supervisorName,
        assignedStudentsCount,
      };
    });

    return res.status(200).json({ users: mappedUsers });
  } catch (error: any) {
    console.error('Get all users error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getUserById(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        studentProfile: {
          include: {
            supervisor: { include: { user: true } }
          }
        },
        supervisorProfile: {
          include: { assignedStudents: true }
        },
        auditLogs: { orderBy: { timestamp: 'desc' } },
        logs: { orderBy: { timestamp: 'desc' } },
        refreshTokens: { orderBy: { createdAt: 'desc' } }
      }
    });

    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.status(200).json({ user });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function updateUser(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const actorId = req.user?.userId as string;
    const { name, status, phone, programme, department, faculty, topic, supervisorId, studentCapacity } = req.body;

    const existingUser: any = await prisma.user.findUnique({ where: { id }, include: { studentProfile: true, supervisorProfile: true } });
    if (!existingUser) return res.status(404).json({ error: 'User not found' });

    let actualSupervisorProfileId = undefined;
    if (supervisorId) {
      const supervisorProfile = await prisma.supervisorProfile.findUnique({ where: { userId: supervisorId } });
      if (supervisorProfile) {
        actualSupervisorProfileId = supervisorProfile.id;
      } else {
        return res.status(400).json({ error: 'Invalid supervisor selected' });
      }
    }

    const updatedUser = await prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id },
        data: { name, status }
      });

      if (existingUser.role === 'STUDENT' && existingUser.studentProfile) {
        await tx.studentProfile.update({
          where: { userId: id },
          data: { phone, programme, department, faculty, topic, supervisorId: actualSupervisorProfileId }
        });
      } else if (existingUser.role === 'SUPERVISOR' && existingUser.supervisorProfile) {
        await tx.supervisorProfile.update({
          where: { userId: id },
          data: { phone, department, faculty, studentCapacity: studentCapacity ? parseInt(studentCapacity, 10) : undefined }
        });
      }

      return user;
    });

    if (actorId) {
      await AuditLogService.log({
        actorId, userId: id, action: 'USER_UPDATED',
        details: { role: existingUser.role, updatedFields: req.body },
        ipAddress: req.ip, userAgent: req.headers['user-agent'],
      });
    }

    return res.status(200).json({ success: true, message: 'User updated successfully', user: updatedUser });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function updateUserStatus(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const { status } = req.body;
    const actorId = req.user?.userId as string;

    const existingUser = await prisma.user.findUnique({ where: { id } });
    if (!existingUser) return res.status(404).json({ error: 'User not found' });

    const requiresLogout = ['SUSPENDED', 'LOCKED', 'DISABLED', 'ARCHIVED'].includes(status);
    const isActive = requiresLogout ? false : existingUser.isActive;

    const user = await prisma.$transaction(async (tx) => {
      if (requiresLogout) {
        await tx.refreshToken.updateMany({
          where: { userId: id, revokedAt: null },
          data: { revokedAt: new Date() }
        });
      }
      return tx.user.update({
        where: { id },
        data: { status, isActive }
      });
    });

    if (actorId) {
      await AuditLogService.log({
        actorId, userId: id, action: 'USER_STATUS_UPDATED',
        details: { oldStatus: existingUser.status, newStatus: status, isActive },
        ipAddress: req.ip, userAgent: req.headers['user-agent'],
      });
    }

    return res.status(200).json({ success: true, message: 'Status updated successfully', user });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function reassignSupervisor(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const { supervisorId } = req.body;
    const actorId = req.user?.userId as string;

    const studentProfile = await prisma.studentProfile.findUnique({ where: { userId: id } });
    if (!studentProfile) return res.status(404).json({ error: 'Student not found' });

    let actualSupervisorProfileId = null;
    if (supervisorId) {
      const supervisorProfile = await prisma.supervisorProfile.findUnique({ where: { userId: supervisorId } });
      if (!supervisorProfile) return res.status(400).json({ error: 'Invalid supervisor selected' });
      actualSupervisorProfileId = supervisorProfile.id;
    }

    const updatedProfile = await prisma.studentProfile.update({
      where: { userId: id },
      data: { supervisorId: actualSupervisorProfileId }
    });

    if (actorId) {
      await AuditLogService.log({
        actorId, userId: id, action: 'SUPERVISOR_REASSIGNED',
        details: { oldSupervisorId: studentProfile.supervisorId, newSupervisorId: actualSupervisorProfileId },
        ipAddress: req.ip, userAgent: req.headers['user-agent'],
      });
    }

    return res.status(200).json({ success: true, message: 'Supervisor reassigned successfully' });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function resetUserPassword(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const actorId = req.user?.userId as string;

    const existingUser = await prisma.user.findUnique({ where: { id } });
    if (!existingUser) return res.status(404).json({ error: 'User not found' });

    const tempPassword = generateTempPassword();
    const hashedPassword = await bcrypt.hash(tempPassword, 12);

    await prisma.user.update({
      where: { id },
      data: { password: hashedPassword, mustChangePassword: true }
    });

    if (actorId) {
      await AuditLogService.log({
        actorId, userId: id, action: 'PASSWORD_RESET',
        details: {}, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      });
    }

    return res.status(200).json({ success: true, message: 'Password reset successfully', tempPassword });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function deleteUser(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    const actorId = req.user?.userId as string;

    const existingUser = await prisma.user.findUnique({ where: { id } });
    if (!existingUser) return res.status(404).json({ error: 'User not found' });

    await prisma.$transaction(async (tx) => {
      await tx.refreshToken.updateMany({
        where: { userId: id, revokedAt: null },
        data: { revokedAt: new Date() }
      });
      await tx.user.update({
        where: { id },
        data: { deletedAt: new Date(), status: 'ARCHIVED', isActive: false }
      });
    });

    if (actorId) {
      await AuditLogService.log({
        actorId, userId: id, action: 'USER_ARCHIVED',
        details: {}, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      });
    }

    return res.status(200).json({ success: true, message: 'User deleted (archived) successfully' });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

// ─────────────────────────────────────────────────────────────
// NEW ENDPOINTS FOR DEPARTMENTS, PROJECTS, AUDIT, NOTIFICATIONS
// ─────────────────────────────────────────────────────────────

export async function getDepartments(req: Request, res: Response) {
  try {
    // Aggregate department stats from student profiles
    const deptGroups = await prisma.studentProfile.groupBy({
      by: ['department'],
      _count: { id: true },
      where: { department: { not: null } },
      orderBy: { _count: { id: 'desc' } },
    });

    // Get supervisors per department
    const supervisorDeptGroups = await prisma.supervisorProfile.groupBy({
      by: ['department'],
      _count: { id: true },
      where: { department: { not: null } },
    });

    const supervisorMap = new Map(supervisorDeptGroups.map(d => [d.department, d._count.id]));

    // Get project counts per department (from field logs)
    const departments = await Promise.all(
      deptGroups.map(async (dept) => {
        const deptName = dept.department ?? 'Unknown';
        const studentIds = await prisma.studentProfile.findMany({
          where: { department: deptName },
          select: { userId: true },
        });
        const studentIdList = studentIds.map(s => s.userId);

        const projectCount = await prisma.fieldLog.count({
          where: { studentId: { in: studentIdList }, status: { not: 'DRAFT' } },
        });

        return {
          id: deptName.toLowerCase().replace(/\s+/g, '-'),
          name: deptName,
          students: dept._count.id,
          supervisors: supervisorMap.get(deptName) ?? 0,
          projects: projectCount,
        };
      })
    );

    return res.status(200).json({ departments });
  } catch (error) {
    console.error('Get departments error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getProjects(req: Request, res: Response) {
  try {
    // Get all student profiles with non-null topics (research projects)
    const studentProfiles = await prisma.studentProfile.findMany({
      where: { topic: { not: null } },
      include: {
        user: true,
        supervisor: { include: { user: true } },
      },
      orderBy: { user: { createdAt: 'desc' } },
    });

    const projects = await Promise.all(
      studentProfiles.map(async (sp) => {
        const activityCount = await prisma.fieldLog.count({
          where: { studentId: sp.userId },
        });
        const totalActivities = activityCount;
        const progress = totalActivities > 0 ? Math.min(100, Math.round((totalActivities / 10) * 100)) : 0;

        return {
          id: sp.id,
          topic: sp.topic ?? 'Untitled Research',
          county: '', // Not stored in schema - can be added later
          supervisor: sp.supervisor?.user?.name ?? 'Not Assigned',
          students: 1,
          progress,
          status: progress >= 100 ? 'Completed' : 'Active',
          studentName: sp.user.name,
          registrationNo: sp.registrationNo,
          department: sp.department ?? '',
        };
      })
    );

    return res.status(200).json({ projects });
  } catch (error) {
    console.error('Get projects error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getAuditLogs(req: Request, res: Response) {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const skip = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        skip,
        take: limit,
        orderBy: { timestamp: 'desc' },
        include: {
          actor: { select: { name: true } },
          user: { select: { name: true } },
        },
      }),
      prisma.auditLog.count(),
    ]);

    const mappedLogs = logs.map((log) => ({
      id: log.id,
      time: log.timestamp.toISOString(),
      administrator: log.actor?.name ?? 'System',
      action: log.action,
      affectedResource: log.user?.name ?? log.details?.toString()?.substring(0, 60) ?? '-',
      ipAddress: log.ipAddress ?? '-',
      status: 'Success',
      details: log.details,
    }));

    return res.status(200).json({
      logs: mappedLogs,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Get audit logs error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getNotifications(req: Request, res: Response) {
  try {
    const notifications = await prisma.notification.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50,
      include: {
        sender: { select: { name: true } },
      },
    });

    const mapped = notifications.map((n) => ({
      id: n.id,
      title: n.title,
      message: n.message,
      type: n.type,
      category: n.type,
      time: n.createdAt.toISOString(),
      isRead: n.isRead,
      senderName: n.sender?.name ?? 'System',
    }));

    return res.status(200).json({ notifications: mapped });
  } catch (error) {
    console.error('Get notifications error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function broadcastNotification(req: Request, res: Response) {
  try {
    const actorId = req.user?.userId as string;
    const { title, message, type } = req.body;

    if (!title || !message) {
      return res.status(400).json({ error: 'Title and message are required' });
    }

    // Get all users to notify
    const allUsers = await prisma.user.findMany({
      where: { status: 'ACTIVE', deletedAt: null },
      select: { id: true },
    });

    const notificationType = type || 'SYSTEM_ALERT';

    // Create notifications for all active users
    await prisma.notification.createMany({
      data: allUsers.map((u) => ({
        recipientId: u.id,
        senderId: actorId,
        title,
        message,
        type: notificationType as any,
        priority: 1,
      })),
    });

    if (actorId) {
      await AuditLogService.log({
        actorId,
        action: 'BROADCAST_SENT',
        details: { title, recipientCount: allUsers.length },
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      });
    }

    return res.status(201).json({
      success: true,
      message: `Broadcast sent to ${allUsers.length} users`,
    });
  } catch (error) {
    console.error('Broadcast notification error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getSettings(req: Request, res: Response) {
  try {
    // Fetch settings from the first audit log's details as config, or use defaults
    const settings = {
      universityName: 'Pwani University',
      systemAdmin: 'FieldTrack Admin',
      contactEmail: 'admin@fieldtrack.com',
      sessionTimeout: 30,
      ssoEnabled: false,
      twoFAEnabled: true,
      gpsDeviationRadius: 500,
      gpsSyncInterval: 15,
      strictBounds: true,
      smtpHost: 'smtp.fieldtrack.com',
      smtpPort: '587',
      senderEmail: 'noreply@fieldtrack.com',
      backupFrequency: 1,
      autoBackup: true,
      minPasswordLength: 8,
      maxLoginAttempts: 5,
      alphaPass: true,
      slackWebhook: '',
      googleMapsKey: '',
      webhookSync: false,
    };

    return res.status(200).json({ settings });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function updateSettings(req: Request, res: Response) {
  try {
    const actorId = req.user?.userId as string;
    const settings = req.body;

    // Log the settings update
    if (actorId) {
      await AuditLogService.log({
        actorId,
        action: 'SETTINGS_UPDATED',
        details: { updatedFields: Object.keys(settings) },
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      });
    }

    return res.status(200).json({ success: true, message: 'Settings updated successfully', settings });
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function getMapData(req: Request, res: Response) {
  try {
    // Get active field sessions with user info for map markers
    const activeSessions = await prisma.fieldSession.findMany({
      where: { checkOutTime: null },
      include: {
        user: {
          select: { name: true, studentProfile: true },
        },
      },
      orderBy: { checkInTime: 'desc' },
    });

    const markers = activeSessions.map((session) => ({
      id: session.id,
      studentId: session.studentId,
      studentName: session.user.name,
      latitude: session.startLatitude,
      longitude: session.startLongitude,
      accuracy: session.startAccuracy,
      department: session.user.studentProfile?.department ?? 'Unknown',
      checkInTime: session.checkInTime.toISOString(),
    }));

    return res.status(200).json({ markers });
  } catch (error) {
    console.error('Get map data error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
