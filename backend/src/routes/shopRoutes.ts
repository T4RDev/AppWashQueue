import { Router } from 'express';
import {
  registerShop,
  searchShops,
  getShopDetail,
  getAvailableSlots
} from '../controllers/shopController';
import { upload } from '../middlewares/upload';

const router = Router();

// สมัครเป็นร้านล้างรถ (พร้อมอัปโหลดสำเนาบัตร ปชช. และรูปหน้าร้าน ≥ 3 รูป)
router.post(
  '/register',
  upload.fields([
    { name: 'id_card', maxCount: 1 },
    { name: 'shop_images', maxCount: 10 }
  ]),
  registerShop
);

// ค้นหา / ดูร้าน (ไม่ต้องล็อกอิน)
router.get('/', searchShops);
router.get('/:id', getShopDetail);
router.get('/:id/available-slots', getAvailableSlots);

export default router;

