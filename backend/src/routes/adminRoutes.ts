import { Router } from 'express';
import {
  getShops,
  updateShopStatus,
  getAllUsers,
  updateUserStatus,
  getDiscounts,
  createDiscount,
  updateDiscountStatus,
  getWithdrawals,
  processWithdrawal,
  getAllBookings,
  getAdminOverview
} from '../controllers/adminController';
import { authenticateToken, requireRole } from '../middlewares/auth';
import { upload } from '../middlewares/upload';

const router = Router();

router.use(authenticateToken);
router.use(requireRole('admin'));

// ภาพรวมระบบ
router.get('/overview', getAdminOverview);

// จัดการร้านค้า
router.get('/shops', getShops);
router.patch('/shops/:id/status', updateShopStatus);

// จัดการผู้ใช้งาน
router.get('/users', getAllUsers);
router.patch('/users/:id/status', updateUserStatus);

// จัดการส่วนลดระบบ
router.get('/discounts', getDiscounts);
router.post('/discounts', createDiscount);
router.patch('/discounts/:id/status', updateDiscountStatus);

// จัดการคำขอถอนเงิน
router.get('/withdrawals', getWithdrawals);
router.patch('/withdrawals/:id/process', upload.single('transfer_proof'), processWithdrawal);

// ดูรายการจองทั้งหมด
router.get('/bookings', getAllBookings);

export default router;

