import { Router } from 'express';
import { getSystemVersion, updateSystemVersion } from './system.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';
const router = Router();
// Public endpoint, no authentication required
router.get('/version', getSystemVersion);
// Protected endpoint for developers/admins to update version settings
router.put('/version', authenticate, authorizeRole(['ADMIN']), updateSystemVersion);
export default router;
