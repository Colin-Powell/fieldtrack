import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import {
  getSettingsInfo,
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

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'storage/avatars/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ storage });

// All settings routes require authentication
router.use(authenticate);

router.get('/info', getSettingsInfo);
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
