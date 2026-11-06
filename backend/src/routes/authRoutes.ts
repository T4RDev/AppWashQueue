import { Router } from 'express';
import {
  register,
  login,
  googleAuth,
  forgotPassword,
  resetPasswordWithOtp,
  getMe,
  updateProfile,
  changePassword
} from '../controllers/authController';
import { authenticateToken } from '../middlewares/auth';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleAuth);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPasswordWithOtp);
router.get('/me', authenticateToken, getMe);
router.put('/profile', authenticateToken, updateProfile);
router.put('/change-password', authenticateToken, changePassword);

export default router;

