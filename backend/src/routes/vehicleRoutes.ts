import { Router } from 'express';
import {
  getMyVehicles,
  addVehicle,
  updateVehicle,
  deleteVehicle
} from '../controllers/vehicleController';
import { authenticateToken } from '../middlewares/auth';

const router = Router();

router.use(authenticateToken); // ทุก endpoint ในกลุ่มนี้ต้องล็อกอิน

router.get('/', getMyVehicles);
router.post('/', addVehicle);
router.put('/:id', updateVehicle);
router.delete('/:id', deleteVehicle);

export default router;
