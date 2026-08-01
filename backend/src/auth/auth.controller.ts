import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import { generateToken, generateRefreshToken, verifyToken } from './jwt.js';
import { AuditLogService } from '../services/audit-log.service.js';
import { authLogger } from '../utils/logger.js';
import { prisma } from '../db.js';

export async function login(req: Request, res: Response) {
  try {
    const { email, registrationNo, password } = req.body;
    const ipAddress = req.ip;
    const userAgent = req.headers['user-agent'];
    
    authLogger.info(`Login attempt from IP: ${ipAddress} - Email: ${email || 'N/A'}, RegNo: ${registrationNo || 'N/A'}`);

    if (!password) {
      return res.status(400).json({ error: 'Password is required' });
    }
    if (!email && !registrationNo) {
      return res.status(400).json({ error: 'Either email or registrationNo is required' });
    }

    let user = null;

    if (email) {
      user = await prisma.user.findUnique({ where: { email } });
    } else if (registrationNo) {
      const studentProfile = await prisma.studentProfile.findUnique({
        where: { registrationNo },
        include: { user: true },
      });
      if (studentProfile) {
        user = studentProfile.user;
      }
    }

    if (!user) {
      authLogger.warn(`Login failed: User not found for email/registrationNo: ${email || registrationNo}`);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if account is locked
    if (user.accountLockedUntil && user.accountLockedUntil > new Date()) {
      await AuditLogService.log({
        userId: user.id,
        action: 'FAILED_LOGIN_LOCKED',
        ipAddress,
        userAgent,
      });
      return res.status(403).json({ error: 'Account is locked due to multiple failed login attempts. Try again later.' });
    }

    // Check account status
    if (user.status !== 'ACTIVE' || !user.isActive) {
      await AuditLogService.log({
        userId: user.id,
        action: 'FAILED_LOGIN_INACTIVE',
        details: { status: user.status },
        ipAddress,
        userAgent,
      });
      return res.status(403).json({ error: 'Account is not active' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      authLogger.warn(`Login failed: Incorrect password for user ${user.id} (${user.email})`);
      // Increment failed attempts
      const attempts = user.failedLoginAttempts + 1;
      const updates: any = { failedLoginAttempts: attempts };
      if (attempts >= 5) {
        // Lock for 15 minutes
        updates.accountLockedUntil = new Date(Date.now() + 15 * 60 * 1000);
        await AuditLogService.log({
          userId: user.id,
          action: 'ACCOUNT_LOCKED',
          details: { attempts },
          ipAddress,
          userAgent,
        });
      }
      await prisma.user.update({ where: { id: user.id }, data: updates });
      
      await AuditLogService.log({
        userId: user.id,
        action: 'FAILED_LOGIN',
        ipAddress,
        userAgent,
      });
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Reset failed attempts on success
    await prisma.user.update({
      where: { id: user.id },
      data: {
        failedLoginAttempts: 0,
        accountLockedUntil: null,
        lastLogin: new Date(),
      },
    });

    const token = generateToken({
      userId: user.id,
      role: user.role,
      email: user.email,
    });
    
    const refreshToken = generateRefreshToken({ userId: user.id });
    
    // Store refresh token
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt,
      },
    });

    await AuditLogService.log({
      userId: user.id,
      action: 'LOGIN',
      ipAddress,
      userAgent,
    });
    
    authLogger.info(`Login successful for user ${user.id} (${user.email})`);

    return res.json({
      success: true,
      token,
      refreshToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        mustChangePassword: user.mustChangePassword,
      },
    });
  } catch (error) {
    authLogger.error('Login error:', { error });
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function refresh(req: Request, res: Response) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    const savedToken = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!savedToken || savedToken.revokedAt || savedToken.expiresAt < new Date()) {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }

    // Verify token cryptographic validity
    try {
      verifyToken(refreshToken);
    } catch (e) {
      return res.status(401).json({ error: 'Invalid token signature' });
    }

    const user = savedToken.user;
    if (user.status !== 'ACTIVE' || !user.isActive) {
      return res.status(403).json({ error: 'Account is not active' });
    }

    const token = generateToken({
      userId: user.id,
      role: user.role,
      email: user.email,
    });

    // Token rotation
    const newRefreshToken = generateRefreshToken({ userId: user.id });
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    
    // Revoke old token
    await prisma.refreshToken.update({
      where: { id: savedToken.id },
      data: { revokedAt: new Date() },
    });
    
    // Create new token
    await prisma.refreshToken.create({
      data: {
        token: newRefreshToken,
        userId: user.id,
        expiresAt,
      },
    });

    return res.json({ success: true, token, refreshToken: newRefreshToken });
  } catch (error) {
    authLogger.error('Refresh token error:', { error });
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function logout(req: Request, res: Response) {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await prisma.refreshToken.updateMany({
        where: { token: refreshToken },
        data: { revokedAt: new Date() },
      });
    }
    
    if (req.user) {
      await AuditLogService.log({
        userId: req.user.userId,
        action: 'LOGOUT',
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      });
    }

    return res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    authLogger.error('Logout error:', { error });
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function changePassword(req: Request, res: Response) {
  try {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    const { currentPassword, newPassword } = req.body;

    const user = await prisma.user.findUnique({ where: { id: req.user.userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ error: 'Incorrect current password' });
    }
    
    // Eased password policy check (Min 6 characters, no strict complexity requirements)
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        mustChangePassword: false,
      },
    });
    
    // Revoke all existing refresh tokens
    await prisma.refreshToken.updateMany({
      where: { userId: user.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await AuditLogService.log({
      userId: user.id,
      action: 'PASSWORD_CHANGED',
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    return res.json({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function me(req: Request, res: Response) {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        mustChangePassword: true,
        studentProfile: {
          select: {
            avatar: true,
            registrationNo: true,
            phone: true,
            topic: true,
            programme: true,
            department: true,
            faculty: true,
            supervisor: {
              select: {
                user: {
                  select: {
                    name: true,
                  }
                }
              }
            }
          }
        },
        supervisorProfile: {
          select: {
            avatar: true,
            staffNumber: true,
            department: true,
            faculty: true,
            specialization: true,
            office: true,
            phone: true,
            studentCapacity: true,
          }
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({ success: true, user });
  } catch (error) {
    console.error('Me error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function forgotPassword(req: Request, res: Response) {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || user.role !== 'SUPERVISOR') {
      // Return success even if user not found to prevent email enumeration
      return res.json({ success: true, message: 'If the email exists, an OTP has been sent.' });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await prisma.user.update({
      where: { id: user.id },
      data: {
        resetPasswordOtp: otp,
        resetPasswordExpires: expiresAt,
      },
    });

    const { emailService } = await import('./email.service.js');
    await emailService.sendPasswordResetOtp(email, otp);

    return res.json({ success: true, message: 'OTP sent successfully' });
  } catch (error) {
    console.error('Forgot password error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function verifyOtp(req: Request, res: Response) {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP are required' });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || user.resetPasswordOtp !== otp || !user.resetPasswordExpires) {
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    if (user.resetPasswordExpires < new Date()) {
      return res.status(400).json({ error: 'OTP has expired' });
    }

    // OTP is valid. Issue a temporary token for password reset
    const token = generateToken({
      userId: user.id,
      role: user.role,
      email: user.email,
    });

    return res.json({ success: true, token, message: 'OTP verified successfully' });
  } catch (error) {
    console.error('Verify OTP error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function resetPassword(req: Request, res: Response) {
  try {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
      where: { id: req.user.userId },
      data: {
        password: hashedPassword,
        resetPasswordOtp: null,
        resetPasswordExpires: null,
        mustChangePassword: false,
      },
    });

    // Revoke all existing refresh tokens
    await prisma.refreshToken.updateMany({
      where: { userId: req.user.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await AuditLogService.log({
      userId: req.user.userId,
      action: 'PASSWORD_RESET',
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    return res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function updateFcmToken(req: Request, res: Response) {
  try {
    const userId = req.user?.userId;
    const { fcmToken } = req.body;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
    
    return res.json({ success: true });
  } catch (error) {
    console.error('Update FCM token error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
