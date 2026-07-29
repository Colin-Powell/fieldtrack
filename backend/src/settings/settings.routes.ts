import { Router } from 'express';
import multer from 'multer';
import {
  getProfileSettings,
  updateProfileSettings,
  updatePassword,
  updateSecuritySettings,
  logoutOtherSessions,
  deactivateAccount,
  updatePreferences,
  uploadAvatar,
  revokeSession
} from './settings.controller.js';
import { authenticate } from '../auth/auth.middleware.js';

const router = Router();
const upload = multer({ dest: 'storage/avatars/' });

// All settings routes require authentication
router.use(authenticate);

router.get('/profile', getProfileSettings);
router.put('/profile', updateProfileSettings);
router.put('/password', updatePassword);
router.put('/security', updateSecuritySettings);
router.post('/logout-others', logoutOtherSessions);
router.delete('/deactivate', deactivateAccount);

router.put('/preferences', updatePreferences);
router.post('/avatar', upload.single('avatar'), uploadAvatar);
router.delete('/sessions/:id', revokeSession);

export default router;
