import { Router } from 'express';
import { submitReview, getShopReviews } from '../controllers/reviewController';
import { authenticateToken } from '../middlewares/auth';

const router = Router();

router.get('/shop/:shopId', getShopReviews);
router.post('/', authenticateToken, submitReview);

export default router;
