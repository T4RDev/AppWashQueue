import { Router } from 'express';
import {
  getMyWallet,
  generateTopUpQR,
  confirmTopUp,
  requestMemberWithdrawal
} from '../controllers/walletController';
import { authenticateToken } from '../middlewares/auth';
import { upload } from '../middlewares/upload';

const router = Router();

router.use(authenticateToken);

router.get('/', getMyWallet);
router.post('/topup/qr', generateTopUpQR);
router.post('/topup/confirm', upload.single('slip'), confirmTopUp);
router.post('/withdraw', requestMemberWithdrawal);

export default router;

