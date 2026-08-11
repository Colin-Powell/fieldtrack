import { Router } from 'express';
import { getSystemVersion } from './system.controller.js';
const router = Router();
// Public endpoint, no authentication required
router.get('/version', getSystemVersion);
export default router;
