import { prisma } from '../db.js';
import * as bcrypt from 'bcrypt';
// GET /api/v1/settings/profile
export const getProfileSettings = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        const userData = await prisma.user.findUnique({
            where: { id: user.userId },
            include: {
                supervisorProfile: true,
                studentProfile: true,
                preferences: true,
                refreshTokens: true,
            },
        });
        if (!userData) {
            res.status(404).json({ success: false, message: 'User not found' });
            return;
        }
        // Omit sensitive data
        const { password, ...safeUser } = userData;
        res.json({ success: true, profile: safeUser });
    }
    catch (error) {
        console.error('getProfileSettings error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// PUT /api/v1/settings/profile
export const updateProfileSettings = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        const { name, phone, department, faculty, specialization, office, topic, programme } = req.body;
        const updatedUser = await prisma.user.update({
            where: { id: user.userId },
            data: {
                name,
                ...(user.role === 'SUPERVISOR'
                    ? {
                        supervisorProfile: {
                            update: {
                                phone,
                                department,
                                faculty,
                                specialization,
                                office,
                            },
                        },
                    }
                    : user.role === 'STUDENT'
                        ? {
                            studentProfile: {
                                update: {
                                    phone,
                                    department,
                                    faculty,
                                    topic,
                                    programme,
                                },
                            },
                        }
                        : {}),
            },
            include: {
                supervisorProfile: true,
                studentProfile: true,
            },
        });
        const { password, ...safeUser } = updatedUser;
        res.json({ success: true, profile: safeUser });
    }
    catch (error) {
        console.error('updateProfileSettings error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// PUT /api/v1/settings/password
export const updatePassword = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        const { currentPassword, newPassword } = req.body;
        if (!currentPassword || !newPassword) {
            res.status(400).json({ success: false, message: 'currentPassword and newPassword are required' });
            return;
        }
        const dbUser = await prisma.user.findUnique({ where: { id: user.userId } });
        if (!dbUser) {
            res.status(404).json({ success: false, message: 'User not found' });
            return;
        }
        const isValid = await bcrypt.compare(currentPassword, dbUser.password);
        if (!isValid) {
            res.status(400).json({ success: false, message: 'Invalid current password' });
            return;
        }
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await prisma.user.update({
            where: { id: user.userId },
            data: { password: hashedPassword },
        });
        res.json({ success: true, message: 'Password updated successfully' });
    }
    catch (error) {
        console.error('updatePassword error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// PUT /api/v1/settings/security
export const updateSecuritySettings = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        const { twoFactorEnabled, loginAlertsEnabled } = req.body;
        await prisma.user.update({
            where: { id: user.userId },
            data: {
                ...(twoFactorEnabled !== undefined && { twoFactorEnabled }),
                ...(loginAlertsEnabled !== undefined && { loginAlertsEnabled }),
            },
        });
        res.json({ success: true, message: 'Security settings updated' });
    }
    catch (error) {
        console.error('updateSecuritySettings error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// POST /api/v1/settings/logout-others
export const logoutOtherSessions = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        await prisma.refreshToken.deleteMany({
            where: { userId: user.userId },
        });
        res.json({ success: true, message: 'All other sessions invalidated' });
    }
    catch (error) {
        console.error('logoutOtherSessions error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// DELETE /api/v1/settings/deactivate
export const deactivateAccount = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        await prisma.user.update({
            where: { id: user.userId },
            data: {
                status: 'SUSPENDED',
                isActive: false,
                deletedAt: new Date(),
            },
        });
        await prisma.refreshToken.deleteMany({
            where: { userId: user.userId },
        });
        res.json({ success: true, message: 'Account deactivated' });
    }
    catch (error) {
        console.error('deactivateAccount error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// PUT /api/v1/settings/preferences
export const updatePreferences = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        const data = req.body;
        await prisma.userPreferences.upsert({
            where: { userId: user.userId },
            update: data,
            create: { ...data, userId: user.userId },
        });
        res.json({ success: true, message: 'Preferences updated' });
    }
    catch (error) {
        console.error('updatePreferences error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// POST /api/v1/settings/avatar
export const uploadAvatar = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        if (!req.file) {
            res.status(400).json({ success: false, message: 'No file uploaded' });
            return;
        }
        // Avatar path relative to backend root
        const avatarPath = `/storage/avatars/${req.file.filename}`;
        await prisma.user.update({
            where: { id: user.userId },
            data: {
                ...(user.role === 'SUPERVISOR'
                    ? { supervisorProfile: { update: { avatar: avatarPath } } }
                    : { studentProfile: { update: { avatar: avatarPath } } }),
            },
        });
        res.json({ success: true, avatar: avatarPath });
    }
    catch (error) {
        console.error('uploadAvatar error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
// DELETE /api/v1/settings/sessions/:id
export const revokeSession = async (req, res) => {
    try {
        const user = req.user;
        if (!user) {
            res.status(401).json({ success: false, message: 'Unauthorized' });
            return;
        }
        const sessionId = req.params.id;
        await prisma.refreshToken.delete({
            where: { id: sessionId },
        });
        res.json({ success: true, message: 'Session revoked' });
    }
    catch (error) {
        console.error('revokeSession error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
