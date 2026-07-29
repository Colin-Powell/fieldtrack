import { Router } from 'express';
import { login, me, refresh, changePassword, forgotPassword, verifyOtp, resetPassword } from './auth.controller.js';
import { authenticate } from './auth.middleware.js';

const router = Router();

router.post('/login', login);
router.post('/refresh', refresh);
router.post('/change-password', authenticate, changePassword);
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', authenticate, resetPassword);
router.get('/me', authenticate, me);

export default router;
