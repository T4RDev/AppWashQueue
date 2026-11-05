import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { createNotification } from '../utils/notification';
import { AuthRequest } from '../types';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

// 1.3.4 (2) ดึงรายการร้านค้าและอนุมัติ / ปฏิเสธ / ระงับร้านล้างรถ
export const getShops = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status } = req.query;
    let query = `
      SELECT s.*, u.email AS owner_email, u.full_name AS owner_name,
             (SELECT COUNT(*) FROM shop_images WHERE shop_id = s.id) AS image_count
      FROM shops s
      JOIN users u ON u.id = s.owner_id
    `;
    const params: any[] = [];
    if (status) {
      query += ' WHERE s.status = ?';
      params.push(status);
    }
    query += ' ORDER BY s.id DESC';

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลร้านค้า', 500, error);
  }
};

export const updateShopStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = req.params.id;
    const { status } = req.body; // 'approved', 'rejected', 'suspended', 'pending'

    const validStatuses = ['approved', 'rejected', 'suspended', 'pending'];
    if (!validStatuses.includes(status)) {
      sendError(res, 'สถานะไม่ถูกต้อง', 400);
      return;
    }

    const [shops] = await pool.execute<RowDataPacket[]>(
      'SELECT id, owner_id, shop_name FROM shops WHERE id = ?',
      [shopId]
    );

    if (shops.length === 0) {
      sendError(res, 'ไม่พบร้านค้านี้', 404);
      return;
    }

    const shop = shops[0];

    await pool.execute('UPDATE shops SET status = ? WHERE id = ?', [status, shopId]);

    // ส่งการแจ้งเตือนไปยังเจ้าของร้าน
    if (status === 'approved') {
      await createNotification(
        shop.owner_id,
        'ร้านของคุณได้รับการอนุมัติแล้ว! 🎊',
        `ยินดีด้วยครับ ร้าน ${shop.shop_name} ผ่านการตรวจสอบและพร้อมเปิดรับคิวลูกค้าแล้ว`,
        'system'
      );
    } else if (status === 'rejected') {
      await createNotification(
        shop.owner_id,
        'คำขอเปิดร้านไม่ผ่านการอนุมัติ',
        `คำขอเปิดร้าน ${shop.shop_name} ไม่ผ่านการอนุมัติ กรุณาตรวจสอบเอกสารหรือติดต่อแอดมิน`,
        'system'
      );
    }

    sendSuccess(res, null, `อัปเดตสถานะร้านเป็น ${status} สำเร็จ`);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการอัปเดตสถานะร้านค้า', 500, error);
  }
};

// 1.3.4 (3, 6) ดูข้อมูลผู้ใช้ทั้งหมดและระงับบัญชี (Suspend / Active)
export const getAllUsers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { role, status, search } = req.query;

    let query = `
      SELECT u.id, u.email, u.full_name, u.phone, u.role, u.status, u.created_at,
             w.balance, w.pending_balance,
             (SELECT COUNT(*) FROM vehicles WHERE user_id = u.id) AS vehicle_count,
             s.id AS shop_id, s.shop_name, s.status AS shop_status
      FROM users u
      LEFT JOIN wallets w ON w.user_id = u.id
      LEFT JOIN shops s ON s.owner_id = u.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (role) {
      query += ' AND u.role = ?';
      params.push(role);
    }
    if (status) {
      query += ' AND u.status = ?';
      params.push(status);
    }
    if (search) {
      query += ' AND (u.email LIKE ? OR u.full_name LIKE ? OR u.phone LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY u.id DESC';

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้', 500, error);
  }
};

export const updateUserStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.params.id;
    const { status } = req.body; // 'active', 'suspended'

    if (!['active', 'suspended'].includes(status)) {
      sendError(res, 'สถานะผู้ใช้ต้องเป็น active หรือ suspended เท่านั้น', 400);
      return;
    }

    // ป้องกันแอดมินระงับบัญชีตัวเอง
    if (Number(userId) === req.user!.id) {
      sendError(res, 'คุณไม่สามารถระงับบัญชีของตนเองได้', 400);
      return;
    }

    await pool.execute('UPDATE users SET status = ? WHERE id = ?', [status, userId]);
    sendSuccess(res, null, `อัปเดตสถานะผู้ใช้เป็น ${status} เรียบร้อยแล้ว`);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการอัปเดตสถานะผู้ใช้', 500, error);
  }
};

// 1.3.4 (5) จัดการโค้ดส่วนลดของระบบ (Discounts)
export const getDiscounts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [rows] = await pool.execute<RowDataPacket[]>(
      `SELECT d.*, u.full_name AS creator_name
       FROM discounts d
       JOIN users u ON u.id = d.created_by
       ORDER BY d.id DESC`
    );
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงโค้ดส่วนลด', 500, error);
  }
};

export const createDiscount = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const adminId = req.user!.id;
    const { code, discount_percent } = req.body;

    if (!code || !discount_percent) {
      sendError(res, 'กรุณาระบุรหัสโค้ด และเปอร์เซ็นต์ส่วนลด', 400);
      return;
    }

    const numPercent = Number(discount_percent);
    if (numPercent <= 0 || numPercent > 100) {
      sendError(res, 'เปอร์เซ็นต์ส่วนลดต้องอยู่ระหว่าง 1 ถึง 100%', 400);
      return;
    }

    const [existing] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM discounts WHERE code = ?',
      [code.toUpperCase()]
    );
    if (existing.length > 0) {
      sendError(res, 'รหัสส่วนลดนี้มีอยู่ในระบบแล้ว', 400);
      return;
    }

    const [result] = await pool.execute<ResultSetHeader>(
      'INSERT INTO discounts (code, discount_percent, is_active, created_by) VALUES (?, ?, TRUE, ?)',
      [code.toUpperCase(), numPercent, adminId]
    );

    sendSuccess(res, { id: result.insertId }, 'สร้างโค้ดส่วนลดสำเร็จ', 201);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการสร้างส่วนลด', 500, error);
  }
};

export const updateDiscountStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const discountId = req.params.id;
    const { is_active } = req.body;

    await pool.execute('UPDATE discounts SET is_active = ? WHERE id = ?', [
      is_active ? 1 : 0,
      discountId
    ]);

    sendSuccess(res, null, 'อัปเดตสถานะส่วนลดเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการอัปเดตส่วนลด', 500, error);
  }
};

// 1.3.4 (4, 8) จัดการคำขอถอนเงินและโอนเงินเข้าบัญชีธนาคาร
export const getWithdrawals = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status } = req.query;
    let query = `
      SELECT w.*, u.full_name AS requester_name, u.email AS requester_email, u.phone AS requester_phone, u.role AS requester_role
      FROM withdrawal_requests w
      JOIN users u ON u.id = w.user_id
    `;
    const params: any[] = [];
    if (status) {
      query += ' WHERE w.status = ?';
      params.push(status);
    }
    query += ' ORDER BY w.id DESC';

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงรายการถอนเงิน', 500, error);
  }
};

export const processWithdrawal = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const adminId = req.user!.id;
    const withdrawalId = req.params.id;
    const { status, admin_notes } = req.body; // 'approved' or 'rejected'
    const file = req.file;

    if (!['approved', 'rejected'].includes(status)) {
      sendError(res, 'สถานะต้องเป็น approved หรือ rejected เท่านั้น', 400);
      return;
    }

    await connection.beginTransaction();

    const [requests] = await connection.execute<RowDataPacket[]>(
      'SELECT * FROM withdrawal_requests WHERE id = ? FOR UPDATE',
      [withdrawalId]
    );

    if (requests.length === 0) {
      await connection.rollback();
      sendError(res, 'ไม่พบคำขอถอนเงินนี้', 404);
      return;
    }

    const wr = requests[0];
    if (wr.status !== 'pending') {
      await connection.rollback();
      sendError(res, 'คำขอนี้ได้รับการประมวลผลไปแล้ว', 400);
      return;
    }

    const transferProofUrl = file ? file.path.replace(/\\/g, '/') : null;

    if (status === 'approved') {
      // อนุมัติการโอนเงิน
      await connection.execute(
        `UPDATE withdrawal_requests 
         SET status = 'approved', transfer_proof_url = ?, admin_notes = ?, processed_by = ?, processed_at = NOW()
         WHERE id = ?`,
        [transferProofUrl, admin_notes || null, adminId, withdrawalId]
      );

      // บันทึกธุรกรรมถอนเงินสำเร็จ
      await connection.execute(
        `INSERT INTO wallet_transactions (wallet_id, amount, type, status, reference_id, notes)
         VALUES (?, ?, 'withdrawal', 'completed', ?, ?)`,
        [
          wr.wallet_id,
          wr.amount,
          `WD-${withdrawalId}`,
          `โอนเงินเข้าบัญชีธนาคาร ${wr.bank_name} (${wr.bank_account_number}) สำเร็จ`
        ]
      );

      await createNotification(
        wr.user_id,
        'การถอนเงินสำเร็จ! 💸',
        `ยอดเงินจำนวน ${wr.amount} บาท ได้รับการโอนเข้าบัญชีธนาคาร ${wr.bank_name} เรียบร้อยแล้ว`,
        'wallet_update'
      );
    } else {
      // ปฏิเสธ -> คืนเงินกลับเข้า balance ของ User/ร้าน
      await connection.execute(
        'UPDATE wallets SET balance = balance + ? WHERE id = ?',
        [wr.amount, wr.wallet_id]
      );

      await connection.execute(
        `UPDATE withdrawal_requests 
         SET status = 'rejected', admin_notes = ?, processed_by = ?, processed_at = NOW()
         WHERE id = ?`,
        [admin_notes || 'คำขอถอนเงินถูกปฏิเสธโดยผู้ดูแลระบบ', adminId, withdrawalId]
      );

      await createNotification(
        wr.user_id,
        'คำขอถอนเงินถูกปฏิเสธ ❌',
        `คำขอถอนเงินจำนวน ${wr.amount} บาท ไม่ผ่านการอนุมัติ (${admin_notes || 'ข้อมูลไม่ถูกต้อง'}) เงินถูกคืนกลับเข้ากระเป๋าของคุณแล้ว`,
        'wallet_update'
      );
    }

    await connection.commit();
    sendSuccess(res, null, `ดำเนินการคำขอถอนเงินเป็น ${status} สำเร็จ`);
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการประมวลผลการถอนเงิน', 500, error);
  } finally {
    connection.release();
  }
};

// 1.3.4 (7) ดูข้อมูลการจองทั้งหมดในระบบ
export const getAllBookings = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status, date, shop_id } = req.query;

    let query = `
      SELECT 
        b.id, b.booking_code, b.booking_date, b.status, b.payment_status,
        b.original_price, b.discount_amount, b.final_price,
        b.shop_share_amount, b.system_fee_amount, b.created_at,
        s.shop_name,
        u.full_name AS customer_name, u.phone AS customer_phone,
        v.plate_number, v.vehicle_type,
        srv.name AS service_name,
        ts.start_time, ts.end_time
      FROM bookings b
      JOIN shops s ON s.id = b.shop_id
      JOIN users u ON u.id = b.user_id
      JOIN vehicles v ON v.id = b.vehicle_id
      JOIN services srv ON srv.id = b.service_id
      JOIN shop_time_slots ts ON ts.id = b.time_slot_id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (status) {
      query += ' AND b.status = ?';
      params.push(status);
    }
    if (date) {
      query += ' AND b.booking_date = ?';
      params.push(date);
    }
    if (shop_id) {
      query += ' AND b.shop_id = ?';
      params.push(shop_id);
    }

    query += ' ORDER BY b.id DESC';

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงรายการจองทั้งหมด', 500, error);
  }
};

// สรุปภาพรวมสำหรับ Dashboard Admin
export const getAdminOverview = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [stats] = await pool.execute<RowDataPacket[]>(`
      SELECT 
        (SELECT COUNT(*) FROM users WHERE role = 'member') AS total_members,
        (SELECT COUNT(*) FROM shops WHERE status = 'approved') AS total_approved_shops,
        (SELECT COUNT(*) FROM shops WHERE status = 'pending') AS total_pending_shops,
        (SELECT COUNT(*) FROM bookings) AS total_bookings,
        (SELECT COUNT(*) FROM bookings WHERE status = 'completed') AS completed_bookings,
        (SELECT COALESCE(SUM(system_fee_amount), 0) FROM bookings WHERE status IN ('completed', 'no_show')) AS total_system_revenue,
        (SELECT COUNT(*) FROM withdrawal_requests WHERE status = 'pending') AS pending_withdrawals
    `);

    sendSuccess(res, stats[0]);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลภาพรวม', 500, error);
  }
};

