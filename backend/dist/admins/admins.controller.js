import bcrypt from 'bcrypt';
import { AuditLogService } from '../services/audit-log.service.js';
import { NotificationService } from '../notifications/notification.service.js';
import { prisma } from '../db.js';
const notificationService = new NotificationService();
// Generate a random temporary password
function generateTempPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    let password = '';
    for (let i = 0; i < 12; i++) {
        password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return password;
}
export async function createStudent(req, res) {
    try {
        const actorId = req.user?.userId;
        const { firstName, lastName, registrationNo, email, phone, programme, department, faculty, researchTopic, supervisorId, } = req.body;
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
            }
            else {
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
    }
    catch (error) {
        console.error('Create student error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function createSupervisor(req, res) {
    try {
        const actorId = req.user?.userId;
        const { fullName, email, phone, staffNumber, department, faculty, office, specialization, studentCapacity, } = req.body;
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
    }
    catch (error) {
        console.error('Create supervisor error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getAllUsers(req, res) {
    try {
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = parseInt(req.query.offset, 10) || 0;
        const [users, total] = await Promise.all([
            prisma.user.findMany({
                take: limit,
                skip: offset,
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
            }),
            prisma.user.count()
        ]);
        const mappedUsers = users.map(user => {
            let regNo;
            let department = '-';
            let supervisorName;
            let assignedStudentsCount;
            let avatarUrl = '';
            if (user.role === 'STUDENT' && user.studentProfile) {
                regNo = user.studentProfile.registrationNo;
                department = user.studentProfile.department ?? '-';
                avatarUrl = user.studentProfile.avatar ?? '';
                if (user.studentProfile.supervisor) {
                    supervisorName = user.studentProfile.supervisor.user.name;
                }
            }
            else if (user.role === 'SUPERVISOR' && user.supervisorProfile) {
                department = user.supervisorProfile.department ?? '-';
                assignedStudentsCount = user.supervisorProfile.assignedStudents?.length || 0;
                avatarUrl = user.supervisorProfile.avatar ?? '';
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
                avatarUrl,
            };
        });
        return res.status(200).json({ users: mappedUsers, total, limit, offset });
    }
    catch (error) {
        console.error('Get all users error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getUserById(req, res) {
    try {
        const id = req.params.id;
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
        if (!user)
            return res.status(404).json({ error: 'User not found' });
        return res.status(200).json({ user });
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function updateUser(req, res) {
    try {
        const id = req.params.id;
        const actorId = req.user?.userId;
        const { name, status, phone, programme, department, faculty, topic, supervisorId, studentCapacity } = req.body;
        const existingUser = await prisma.user.findUnique({ where: { id }, include: { studentProfile: true, supervisorProfile: true } });
        if (!existingUser)
            return res.status(404).json({ error: 'User not found' });
        let actualSupervisorProfileId = undefined;
        if (supervisorId) {
            const supervisorProfile = await prisma.supervisorProfile.findUnique({ where: { userId: supervisorId } });
            if (supervisorProfile) {
                actualSupervisorProfileId = supervisorProfile.id;
            }
            else {
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
            }
            else if (existingUser.role === 'SUPERVISOR' && existingUser.supervisorProfile) {
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
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function updateUserStatus(req, res) {
    try {
        const id = req.params.id;
        const { status } = req.body;
        const actorId = req.user?.userId;
        const existingUser = await prisma.user.findUnique({ where: { id } });
        if (!existingUser)
            return res.status(404).json({ error: 'User not found' });
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
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function reassignSupervisor(req, res) {
    try {
        const id = req.params.id;
        const { supervisorId } = req.body;
        const actorId = req.user?.userId;
        const studentProfile = await prisma.studentProfile.findUnique({ where: { userId: id } });
        if (!studentProfile)
            return res.status(404).json({ error: 'Student not found' });
        let actualSupervisorProfileId = null;
        if (supervisorId) {
            const supervisorProfile = await prisma.supervisorProfile.findUnique({ where: { userId: supervisorId } });
            if (!supervisorProfile)
                return res.status(400).json({ error: 'Invalid supervisor selected' });
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
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function resetUserPassword(req, res) {
    try {
        const id = req.params.id;
        const { newPassword } = req.body;
        const actorId = req.user?.userId;
        const existingUser = await prisma.user.findUnique({ where: { id } });
        if (!existingUser)
            return res.status(404).json({ error: 'User not found' });
        const passwordToUse = newPassword || generateTempPassword();
        const hashedPassword = await bcrypt.hash(passwordToUse, 12);
        await prisma.user.update({
            where: { id },
            data: { password: hashedPassword, mustChangePassword: true }
        });
        if (actorId) {
            await AuditLogService.log({
                actorId, userId: id, action: 'PASSWORD_RESET',
                details: { autoGenerated: !newPassword }, ipAddress: req.ip, userAgent: req.headers['user-agent'],
            });
        }
        return res.status(200).json({
            success: true,
            message: 'Password reset successfully',
            tempPassword: !newPassword ? passwordToUse : undefined
        });
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function deleteUser(req, res) {
    try {
        const id = req.params.id;
        const actorId = req.user?.userId;
        const existingUser = await prisma.user.findUnique({ where: { id } });
        if (!existingUser)
            return res.status(404).json({ error: 'User not found' });
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
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
// ─────────────────────────────────────────────────────────────
// NEW ENDPOINTS FOR DEPARTMENTS, PROJECTS, AUDIT, NOTIFICATIONS
// ─────────────────────────────────────────────────────────────
export async function getDepartments(req, res) {
    try {
        const dbDepartments = await prisma.department.findMany({
            orderBy: { name: 'asc' },
        });
        const deptGroups = await prisma.studentProfile.groupBy({
            by: ['department'],
            _count: { id: true },
            where: { department: { not: null } },
            orderBy: { _count: { id: 'desc' } },
        });
        const supervisorDeptGroups = await prisma.supervisorProfile.groupBy({
            by: ['department'],
            _count: { id: true },
            where: { department: { not: null } },
        });
        const supervisorMap = new Map(supervisorDeptGroups.map(d => [d.department, d._count.id]));
        const allDepartmentNames = new Set([
            ...dbDepartments.map(d => d.name),
            ...deptGroups.map(d => d.department),
            ...supervisorDeptGroups.map(d => d.department)
        ]);
        const departments = await Promise.all(Array.from(allDepartmentNames).map(async (deptName) => {
            const studentCount = deptGroups.find(d => d.department === deptName)?._count.id ?? 0;
            const supervisorCount = supervisorMap.get(deptName) ?? 0;
            const studentIds = await prisma.studentProfile.findMany({
                where: { department: deptName },
                select: { userId: true },
            });
            let projectCount = 0;
            if (studentIds.length > 0) {
                projectCount = await prisma.fieldLog.count({
                    where: { studentId: { in: studentIds.map(s => s.userId) }, status: { not: 'DRAFT' } },
                });
            }
            const dbDept = dbDepartments.find(d => d.name === deptName);
            return {
                id: dbDept?.id ?? deptName.toLowerCase().replace(/\s+/g, '-'),
                name: deptName,
                description: dbDept?.description,
                students: studentCount,
                supervisors: supervisorCount,
                projects: projectCount,
            };
        }));
        return res.status(200).json({ departments });
    }
    catch (error) {
        console.error('Get departments error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function createDepartment(req, res) {
    try {
        const { name, code, faculty, description } = req.body;
        if (!name)
            return res.status(400).json({ error: 'Department name is required' });
        const existing = await prisma.department.findUnique({ where: { name } });
        if (existing)
            return res.status(400).json({ error: 'Department already exists' });
        const department = await prisma.department.create({
            data: { name, code, faculty, description },
        });
        return res.status(201).json(department);
    }
    catch (error) {
        console.error('Create department error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getDepartmentDetails(req, res) {
    try {
        const deptNameParam = req.params.id;
        // The frontend passes dept.name in the URL
        let dbDept = await prisma.department.findFirst({
            where: { name: { equals: deptNameParam, mode: 'insensitive' } }
        });
        const exactName = dbDept?.name || deptNameParam;
        const students = await prisma.studentProfile.findMany({
            where: { department: { equals: exactName, mode: 'insensitive' } },
            include: { user: { select: { id: true, name: true, email: true } } }
        });
        const supervisors = await prisma.supervisorProfile.findMany({
            where: { department: { equals: exactName, mode: 'insensitive' } },
            include: { user: { select: { id: true, name: true, email: true } } }
        });
        const studentsMapped = students.map(s => ({
            ...s,
            user: { ...s.user, avatar: s.avatar }
        }));
        const supervisorsMapped = supervisors.map(s => ({
            ...s,
            user: { ...s.user, avatar: s.avatar }
        }));
        const projects = students.filter(s => s.topic != null).map(s => ({
            id: s.id,
            title: s.topic,
            studentName: s.user.name,
            studentId: s.userId
        }));
        const studentIds = students.map(s => s.userId);
        const fieldLogs = await prisma.fieldLog.findMany({
            where: { studentId: { in: studentIds } },
            include: { evidence: true, user: true }
        });
        const evidenceList = fieldLogs.flatMap(log => log.evidence.map(e => ({
            id: e.id,
            activityTitle: log.title,
            studentName: log.user.name,
            storedName: e.storedName,
            originalName: e.originalName,
            mimeType: e.mimeType,
            uploadedAt: e.uploadedAt
        })));
        return res.status(200).json({
            department: dbDept ?? { id: deptNameParam, name: exactName },
            students: studentsMapped,
            supervisors: supervisorsMapped,
            projects,
            evidence: evidenceList
        });
    }
    catch (error) {
        console.error('Get department details error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function globalSearch(req, res) {
    try {
        const q = req.query.q;
        if (!q)
            return res.status(200).json({ users: [], departments: [], projects: [] });
        const [users, departments, projects] = await Promise.all([
            prisma.user.findMany({
                where: { OR: [{ name: { contains: q, mode: 'insensitive' } }, { email: { contains: q, mode: 'insensitive' } }] },
                take: 5,
                select: { id: true, name: true, email: true, role: true }
            }),
            prisma.department.findMany({
                where: { name: { contains: q, mode: 'insensitive' } },
                take: 5
            }),
            prisma.studentProfile.findMany({
                where: { topic: { contains: q, mode: 'insensitive' } },
                take: 5,
                include: { user: { select: { name: true } } }
            })
        ]);
        const usersMapped = await Promise.all(users.map(async (u) => {
            let avatar = null;
            if (u.role === 'STUDENT') {
                const p = await prisma.studentProfile.findUnique({ where: { userId: u.id }, select: { avatar: true } });
                avatar = p?.avatar;
            }
            else if (u.role === 'SUPERVISOR') {
                const p = await prisma.supervisorProfile.findUnique({ where: { userId: u.id }, select: { avatar: true } });
                avatar = p?.avatar;
            }
            return { ...u, avatar };
        }));
        const dynamicDepts = await prisma.studentProfile.groupBy({
            by: ['department'],
            where: { department: { contains: q, mode: 'insensitive' } },
            orderBy: { _count: { id: 'desc' } },
            take: 5
        });
        // Convert implicitly any types to concrete string arrays
        const dynDeptNames = dynamicDepts.map((d) => d.department).filter((d) => d != null);
        const dbDeptNames = departments.map((d) => d.name);
        const allDepts = new Set([...dbDeptNames, ...dynDeptNames]);
        return res.status(200).json({
            users: usersMapped,
            departments: Array.from(allDepts).map((name) => ({ name, id: departments.find((d) => d.name === name)?.id || name })),
            projects: projects.map((p) => ({ id: p.id, title: p.topic, studentName: p.user.name, studentId: p.userId }))
        });
    }
    catch (error) {
        console.error('Global search error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getProjects(req, res) {
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
        const projects = await Promise.all(studentProfiles.map(async (sp) => {
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
                studentUserId: sp.userId,
            };
        }));
        return res.status(200).json({ projects });
    }
    catch (error) {
        console.error('Get projects error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getAuditLogs(req, res) {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
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
    }
    catch (error) {
        console.error('Get audit logs error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getNotifications(req, res) {
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
    }
    catch (error) {
        console.error('Get notifications error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function broadcastNotification(req, res) {
    try {
        const actorId = req.user?.userId;
        const { title, message, type } = req.body;
        if (!title || !message) {
            return res.status(400).json({ error: 'Title and message are required' });
        }
        // Get all active supervisor and student users to notify
        const allUsers = await prisma.user.findMany({
            where: {
                role: { in: ['STUDENT', 'SUPERVISOR'] },
                status: 'ACTIVE',
                isActive: true,
                deletedAt: null,
            },
            select: { id: true },
        });
        const notificationType = type || 'SYSTEM_ALERT';
        // Extract just the user IDs for the background job
        const recipientIds = allUsers.map(u => u.id);
        // Using BullMQ for background processing
        const { notificationQueue } = await import('../utils/queue.js');
        await notificationQueue.add('bulkNotification', {
            recipientIds,
            senderId: actorId,
            title,
            message,
            type: notificationType,
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
    }
    catch (error) {
        console.error('Broadcast notification error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getSettings(req, res) {
    try {
        // Default settings
        const defaults = {
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
            smtpPassword: '',
            s3BucketUri: 's3://fieldtrack-prod-backups',
            backupFrequency: 1,
            autoBackup: true,
            minPasswordLength: 8,
            maxLoginAttempts: 5,
            alphaPass: true,
            slackWebhook: '',
            googleMapsKey: '',
            webhookSync: false,
        };
        // Try to read from DB, merge with defaults
        const settingsRecord = await prisma.systemSetting.findUnique({
            where: { key: 'admin_settings' },
        });
        if (settingsRecord && settingsRecord.value) {
            const savedSettings = settingsRecord.value;
            const merged = { ...defaults, ...savedSettings };
            return res.status(200).json({ settings: merged });
        }
        return res.status(200).json({ settings: defaults });
    }
    catch (error) {
        console.error('getSettings error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function updateSettings(req, res) {
    try {
        const actorId = req.user?.userId;
        const settings = req.body;
        // Persist settings to the SystemSetting table
        await prisma.systemSetting.upsert({
            where: { key: 'admin_settings' },
            update: {
                value: settings,
                updatedBy: actorId,
            },
            create: {
                key: 'admin_settings',
                value: settings,
                updatedBy: actorId,
            },
        });
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
    }
    catch (error) {
        console.error('updateSettings error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getSettingsHistory(req, res) {
    try {
        // Return last 20 SETTINGS_UPDATED audit logs
        const logs = await prisma.auditLog.findMany({
            where: { action: 'SETTINGS_UPDATED' },
            orderBy: { timestamp: 'desc' },
            take: 20,
            include: {
                actor: { select: { name: true } },
            },
        });
        const history = logs.map((log) => ({
            id: log.id,
            updatedBy: log.actor?.name ?? 'System',
            fields: log.details ? log.details?.updatedFields ?? [] : [],
            timestamp: log.timestamp.toISOString(),
        }));
        return res.status(200).json({ history });
    }
    catch (error) {
        console.error('getSettingsHistory error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function manualBackup(req, res) {
    try {
        const actorId = req.user?.userId;
        // Log the manual backup action
        if (actorId) {
            await AuditLogService.log({
                actorId,
                action: 'MANUAL_BACKUP',
                details: { initiatedBy: actorId, timestamp: new Date().toISOString() },
                ipAddress: req.ip,
                userAgent: req.headers['user-agent'],
            });
        }
        return res.status(200).json({ success: true, message: 'Manual backup initiated successfully' });
    }
    catch (error) {
        console.error('manualBackup error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
export async function getMapData(req, res) {
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
            avatarUrl: session.user.studentProfile?.avatar ?? '',
            checkInTime: session.checkInTime.toISOString(),
        }));
        return res.status(200).json({ markers });
    }
    catch (error) {
        console.error('Get map data error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
}
