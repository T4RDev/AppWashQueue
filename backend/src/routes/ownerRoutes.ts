import { Router } from 'express';
import {
  getMyShop,
  updateMyShop,
  getOperatingDays,
  updateOperatingDays,
  getTimeSlots,
  addTimeSlot,
  updateTimeSlot,
  deleteTimeSlot,
  getServices,
  addService,
  updateService,
  deleteService,
  getShopBookings,
  updateBookingStatus,
  getShopStats,
  requestOwnerWithdrawal
} from '../controllers/ownerController';
import { authenticateToken, requireRole } from '../middlewares/auth';

const router = Router();

// ล็อกอินและต้องมี Role: owner
router.use(authenticateToken);
router.use(requireRole('owner'));

// ข้อมูลร้าน
router.get('/shop', getMyShop);
router.put('/shop', updateMyShop);

// วันเปิดทำการ
router.get('/operating-days', getOperatingDays);
router.put('/operating-days', updateOperatingDays);

// สล็อตเวลา
router.get('/time-slots', getTimeSlots);
router.post('/time-slots', addTimeSlot);
router.put('/time-slots/:id', updateTimeSlot);
router.delete('/time-slots/:id', deleteTimeSlot);

// บริการและราคา
router.get('/services', getServices);
router.post('/services', addService);
router.put('/services/:id', updateService);
router.delete('/services/:id', deleteService);

// รายการจอง & อัปเดตสถานะ
router.get('/bookings', getShopBookings);
patch('/bookings/:id/status', updateBookingStatus);

// สถิติ & ถอนเงิน
router.get('/stats', getShopStats);
router.post('/withdraw', requestOwnerWithdrawal);

export default router;

function patch(path: string, handler: any) {
  router.patch(path, handler);
}

