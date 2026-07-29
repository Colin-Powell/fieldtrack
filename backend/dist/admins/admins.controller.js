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
        // In a real app, send email with tempPassword here
        return res.status(201).json({
            success: true,
            message: 'Student created successfully',
            tempPassword, // Returning for testing purposes
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
                    studentCapacity: studentCapacity ? parseInt(studentCapacity, 10) : 20,
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
            }
            else if (user.role === 'SUPERVISOR' && user.supervisorProfile) {
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
                logs: { orderBy: { timestamp: 'desc' } }, // FieldLogs
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
        const actorId = req.user?.userId;
        const existingUser = await prisma.user.findUnique({ where: { id } });
        if (!existingUser)
            return res.status(404).json({ error: 'User not found' });
        const tempPassword = generateTempPassword(); // generateTempPassword is locally defined above
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
                actorId, userId: id, action: 'USER_ARCHIVED', // soft deleted
                details: {}, ipAddress: req.ip, userAgent: req.headers['user-agent'],
            });
        }
        return res.status(200).json({ success: true, message: 'User deleted (archived) successfully' });
    }
    catch (error) {
        return res.status(500).json({ error: 'Internal server error' });
    }
}
