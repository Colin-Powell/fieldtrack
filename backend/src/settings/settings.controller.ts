import { Request, Response } from 'express';
import { prisma } from '../db.js';
import * as bcrypt from 'bcrypt';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import { getStorageBucket } from '../firebase_admin.js';
import { emailService } from '../auth/email.service.js';

// GET /api/v1/settings/info
export const getSettingsInfo = async (req: Request, res: Response): Promise<void> => {
  try {
    const settingsRecord = await prisma.systemSetting.findUnique({
      where: { key: 'student_help_info' },
    });

    const defaults = {
      faqs: [
        {
          question: 'How do I capture a new field entry?',
          answer:
            'Navigate to the Home screen and tap the large + button. Make sure your GPS is turned on.',
        },
        {
          question: 'Why is my data not syncing?',
          answer:
            'Ensure you have an active internet connection and that Offline Sync is enabled in settings.',
        },
      ],
      supportEmail: 'support@fieldtrack.com',
      privacyPolicy:
        'FieldTrack Privacy Policy\n\nLast Updated: October 2024\n\n1. Information Collection\nWe collect location data and field metrics you input to assist in environmental research. Your personal information (Name, ID, Email) is used strictly for authentication and academic tracking.\n\n2. Data Usage\nAll geographic and analytical data collected is synced to university servers and may be used in aggregated research studies. Individual user tracking is kept confidential.\n\n3. Offline Data\nData stored locally on your device remains encrypted until a secure connection is established for syncing.\n\n(This is a sample privacy policy for demonstration purposes. In a real application, place your full legal terms here.)',
      about: {
        title: 'FieldTrack',
        version: 'Version 1.0.0 (Build 42)',
        description: 'Developed for\nPwani University, Environmental Sciences',
      },
    };

    const savedSettings =
      settingsRecord && typeof settingsRecord.value === 'object'
        ? (settingsRecord.value as Record<string, any>)
        : {};

    const info = {
      ...defaults,
      ...savedSettings,
      about: {
        ...defaults.about,
        ...((savedSettings.about as Record<string, any>) ?? {}),
      },
    };

    res.json({ success: true, info });
  } catch (error: any) {
    console.error('getSettingsInfo error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// GET /api/v1/settings/profile
export const getProfileSettings = async (req: Request, res: Response): Promise<void> => {
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
  } catch (error: any) {
    console.error('getProfileSettings error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/v1/settings/profile
export const updateProfileSettings = async (req: Request, res: Response): Promise<void> => {
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
  } catch (error: any) {
    console.error('updateProfileSettings error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/v1/settings/password
export const updatePassword = async (req: Request, res: Response): Promise<void> => {
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
  } catch (error: any) {
    console.error('updatePassword error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/v1/settings/security
export const updateSecuritySettings = async (req: Request, res: Response): Promise<void> => {
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
  } catch (error: any) {
    console.error('updateSecuritySettings error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// POST /api/v1/settings/logout-others
export const logoutOtherSessions = async (req: Request, res: Response): Promise<void> => {
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
  } catch (error: any) {
    console.error('logoutOtherSessions error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// DELETE /api/v1/settings/deactivate
export const deactivateAccount = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const dbUser = await prisma.user.findUnique({ where: { id: user.userId } });

    await prisma.user.update({
      where: { id: user.userId },
      data: {
        status: 'ARCHIVED',
        isActive: false,
        deletedAt: new Date(),
      },
    });

    if (dbUser?.email) {
      try {
        await emailService.sendEmail(
          dbUser.email,
          'Your FieldTrack Account has been Deactivated',
          `<p>Hello ${dbUser.name},</p>
           <p>Your FieldTrack account has been successfully deactivated as requested. Your account is now inactive and you will not be able to log in.</p>
           <p>If this was a mistake or you wish to reactivate your account, please contact support.</p>
           <p>Thank you,</p>
           <p>The FieldTrack Team</p>`
        );
      } catch (err) {
        console.error('Failed to send deactivation email', err);
      }
    }
    
    await prisma.refreshToken.deleteMany({
      where: { userId: user.userId },
    });

    res.json({ success: true, message: 'Account deactivated successfully' });
  } catch (error: any) {
    console.error('deactivateAccount error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/v1/settings/preferences
export const updatePreferences = async (req: Request, res: Response): Promise<void> => {
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
  } catch (error: any) {
    console.error('updatePreferences error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// POST /api/v1/settings/avatar
export const uploadAvatar = async (req: Request, res: Response): Promise<void> => {
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

    // ── Compress & convert to WebP using sharp ──────────────────────────
    const originalPath = req.file.path;
    const baseName = path.basename(originalPath, path.extname(originalPath));
    const outputPath = path.join(path.dirname(originalPath), `${baseName}.webp`);

    await sharp(originalPath)
      .resize(400, 400, { fit: 'cover', position: 'centre' })
      .webp({ quality: 80 })
      .toFile(outputPath);

    // Remove the original (uncompressed) file
    await fs.unlink(originalPath);

    // Upload to Firebase Storage
    const bucket = getStorageBucket();
    if (!bucket) {
      throw new Error('Firebase Storage Bucket is not configured.');
    }
    const firebasePath = `avatars/${baseName}.webp`;
    
    const token = crypto.randomUUID();
    
    await bucket.upload(outputPath, {
      destination: firebasePath,
      metadata: { 
        contentType: 'image/webp', 
        cacheControl: 'public, max-age=31536000',
        metadata: {
          firebaseStorageDownloadTokens: token,
        }
      }
    });
    
    await fs.unlink(outputPath);

    // Public Firebase URL with download token attached
    const avatarPath = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(firebasePath)}?alt=media&token=${token}`;

    // Fetch existing avatar to delete later
    const existingUser = await prisma.user.findUnique({
      where: { id: user.userId },
      include: {
        studentProfile: true,
        supervisorProfile: true,
      },
    });

    const oldAvatarPath =
      user.role === 'SUPERVISOR'
        ? existingUser?.supervisorProfile?.avatar
        : existingUser?.studentProfile?.avatar;

    await prisma.user.update({
      where: { id: user.userId },
      data: {
        ...(user.role === 'SUPERVISOR'
          ? { supervisorProfile: { update: { avatar: avatarPath } } }
          : { studentProfile: { update: { avatar: avatarPath } } }),
      },
    });

    // Clean up old avatar
    if (oldAvatarPath) {
      if (oldAvatarPath.startsWith('https://storage.googleapis.com/')) {
        // Delete from Firebase
        const oldFirebasePath = oldAvatarPath.split(`https://storage.googleapis.com/${bucket.name}/`)[1];
        if (oldFirebasePath) {
          try {
            await bucket.file(oldFirebasePath).delete();
          } catch (err) {
            console.error('Failed to delete old avatar from firebase:', err);
          }
        }
      } else if (oldAvatarPath.startsWith('/storage/avatars/')) {
        // Legacy local file cleanup
        const fullOldAvatarPath = path.join(process.cwd(), oldAvatarPath);
        try {
          await fs.unlink(fullOldAvatarPath);
        } catch (err: any) {
          if (err.code !== 'ENOENT') {
            console.error('Failed to delete legacy old avatar:', err);
          }
        }
      }
    }

    res.json({ success: true, avatar: avatarPath });
  } catch (error: any) {
    console.error('uploadAvatar error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// DELETE /api/v1/settings/sessions/:id
export const revokeSession = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const sessionId = req.params.id as string;
    await prisma.refreshToken.delete({
      where: { id: sessionId },
    });

    res.json({ success: true, message: 'Session revoked' });
  } catch (error: any) {
    console.error('revokeSession error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

