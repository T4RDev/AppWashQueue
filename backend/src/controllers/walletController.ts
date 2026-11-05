import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../types';
import promptpayQR from 'promptpay-qr';
import QRCode from 'qrcode';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

// ดึงข้อมูลยอดเงินในกระเป๋าและประวัติธุรกรรม
export const getMyWallet = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;

    const [walletRows] = await pool.execute<RowDataPacket[]>(
      'SELECT id, balance, pending_balance, updated_at FROM wallets WHERE user_id = ?',
      [userId]
    );

    if (walletRows.length === 0) {
      sendError(res, 'ไม่พบกระเป๋าเงิน', 404);
      return;
    }

    const wallet = walletRows[0];

    // ดึงประวัติรายการล่าสุด 20 รายการ
    const [transactions] = await pool.execute<RowDataPacket[]>(
      `SELECT id, amount, type, status, reference_id, slip_url, notes, created_at
       FROM wallet_transactions
       WHERE wallet_id = ?
       ORDER BY created_at DESC LIMIT 20`,
      [wallet.id]
    );

    sendSuccess(res, {
      ...wallet,
      transactions
    });
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลกระเป๋าเงิน', 500, error);
  }
};

// 1.3.2 (7) สร้าง QR Code พร้อมเพย์สำหรับเติมเงิน Wallet
export const generateTopUpQR = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { amount } = req.body;

    if (!amount || Number(amount) <= 0) {
      sendError(res, 'กรุณาระบุจำนวนเงินที่ต้องการเติมให้ถูกต้อง', 400);
      return;
    }

    // หมายเลขพร้อมเพย์กลางของระบบ (เช่น หมายเลขผู้เสียภาษีหรือเบอร์โทรแอดมิน)
    const promptPayTarget = process.env.SYSTEM_PROMPTPAY_NUMBER || '0800000000';
    const numAmount = Number(amount);

    // สร้าง PromptPay Payload ตามมาตรฐาน EMVCo
    const payload = promptpayQR(promptPayTarget, { amount: numAmount });

    // แปลงเป็น QR Code Data URL (Base64 Image)
    const qrDataUrl = await QRCode.toDataURL(payload, {
      errorCorrectionLevel: 'M',
      margin: 2,
      scale: 8
    });

    sendSuccess(res, {
      amount: numAmount,
      promptpay_target: promptPayTarget,
      qr_code_image: qrDataUrl,
      raw_payload: payload
    });
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการสร้าง QR Code', 500, error);
  }
};

// ยืนยันการเติมเงินเข้า Wallet (อัปโหลดสลิป หรือ จำลองการเติมเงิน)
export const confirmTopUp = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user!.id;
    const { amount } = req.body;
    const file = req.file;

    if (!amount || Number(amount) <= 0) {
      sendError(res, 'จำนวนเงินไม่ถูกต้อง', 400);
      return;
    }

    const numAmount = Number(amount);

    await connection.beginTransaction();

    const [wallets] = await connection.execute<RowDataPacket[]>(
      'SELECT id FROM wallets WHERE user_id = ? FOR UPDATE',
      [userId]
    );

    if (wallets.length === 0) {
      await connection.rollback();
      sendError(res, 'ไม่พบกระเป๋าเงิน', 404);
      return;
    }

    const walletId = wallets[0].id;

    // เติมเงินเข้ากระเป๋า
    await connection.execute('UPDATE wallets SET balance = balance + ? WHERE id = ?', [
      numAmount,
      walletId
    ]);

    // บันทึกธุรกรรม
    const slipUrl = file ? file.path.replace(/\\/g, '/') : null;
    await connection.execute(
      `INSERT INTO wallet_transactions (wallet_id, amount, type, status, slip_url, notes)
       VALUES (?, ?, 'topup', 'completed', ?, 'เติมเงินเข้ากระเป๋าเงินสำเร็จผ่านการสแกน QR Code')`,
      [walletId, numAmount, slipUrl]
    );

    await connection.commit();

    sendSuccess(res, { added_amount: numAmount }, 'เติมเงินเข้ากระเป๋าเงินสำเร็จเรียบร้อยแล้ว');
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการเติมเงิน', 500, error);
  } finally {
    connection.release();
  }
};

// สมาชิกยื่นคำขอถอนเงินเข้าบัญชีธนาคาร
export const requestMemberWithdrawal = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user!.id;
    const { amount, bank_name, bank_account_name, bank_account_number } = req.body;

    if (!amount || !bank_name || !bank_account_name || !bank_account_number) {
      sendError(res, 'กรุณากรอกข้อมูลการถอนเงินและบัญชีธนาคารให้ครบถ้วน', 400);
      return;
    }

    const numAmount = Number(amount);

    await connection.beginTransaction();

    const [wallets] = await connection.execute<RowDataPacket[]>(
      'SELECT id, balance FROM wallets WHERE user_id = ? FOR UPDATE',
      [userId]
    );

    if (wallets.length === 0 || Number(wallets[0].balance) < numAmount) {
      await connection.rollback();
      sendError(res, 'ยอดเงินคงเหลือในกระเป๋าไม่เพียงพอสำหรับการถอน', 400);
      return;
    }

    const walletId = wallets[0].id;

    // หักเงินออกจาก balance เพื่อรอแอดมินอนุมัติโอน
    await connection.execute('UPDATE wallets SET balance = balance - ? WHERE id = ?', [
      numAmount,
      walletId
    ]);

    // บันทึกคำขอถอนเงิน
    await connection.execute(
      `INSERT INTO withdrawal_requests (
        user_id, wallet_id, amount, bank_name, bank_account_name, bank_account_number, status
      ) VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [userId, walletId, numAmount, bank_name, bank_account_name, bank_account_number]
    );

    await connection.commit();

    sendSuccess(res, null, 'ส่งคำขอถอนเงินสำเร็จ กรุณารอผู้ดูแลระบบตรวจสอบและโอนเงินเข้าบัญชีธนาคาร', 201);
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการถอนเงิน', 500, error);
  } finally {
    connection.release();
  }
};

