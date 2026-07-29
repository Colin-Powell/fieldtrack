import { Router } from 'express';
import { 
  createStudent, createSupervisor, getAllUsers,
  getUserById, updateUser, updateUserStatus,
  reassignSupervisor, resetUserPassword, deleteUser
} from './admins.controller.js';
import { authenticate, authorizeRole } from '../auth/auth.middleware.js';

const router = Router();

// Protect all admin routes
router.use(authenticate, authorizeRole(['ADMIN']));

router.post('/users/students', createStudent);
router.post('/users/supervisors', createSupervisor);
router.get('/users', getAllUsers);

router.get('/users/:id', getUserById);
router.put('/users/:id', updateUser);
router.patch('/users/:id/status', updateUserStatus);
router.patch('/users/:id/supervisor', reassignSupervisor);
router.post('/users/:id/reset-password', resetUserPassword);
router.delete('/users/:id', deleteUser);

export default router;
