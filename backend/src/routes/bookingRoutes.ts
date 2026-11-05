import { Router } from 'express';
import { createBooking, getMyBookings, cancelBooking } from '../controllers/bookingController';
import { authenticateToken } from '../middlewares/auth';

const router = Router();

router.use(authenticateToken);

router.post('/', createBooking);
router.get('/my', getMyBookings);
router.post('/:id/cancel', cancelBooking);

export default router;

