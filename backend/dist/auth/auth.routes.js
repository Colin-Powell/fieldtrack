import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { validate } from './validation.middleware.js';
import { loginSchema } from './auth.schema.js';
import { login, me, refresh, logout, changePassword, forgotPassword, verifyOtp, resetPassword, updateFcmToken } from './auth.controller.js';
import { authenticate } from './auth.middleware.js';
const router = Router();
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // Limit each IP to 5 failed login requests per window
    message: 'Too many login attempts from this IP, please try again after 15 minutes',
});
router.post('/login', loginLimiter, validate(loginSchema), login);
router.post('/logout', authenticate, logout);
router.post('/refresh', refresh);
router.post('/change-password', authenticate, changePassword);
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', authenticate, resetPassword);
router.get('/me', authenticate, me);
router.put('/fcm-token', authenticate, updateFcmToken);
export default router;
