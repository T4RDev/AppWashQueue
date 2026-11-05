import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { createNotification } from '../utils/notification';
import { AuthRequest } from '../types';
import { ResultSetHeader, RowDataPacket } from 'mysql2';

// Helper ดึง shop_id ของ Owner คนปัจจุบัน
const getOwnerShopId = async (ownerId: number): Promise<number | null> => {
  const [rows] = await pool.execute<RowDataPacket[]>(
    'SELECT id FROM shops WHERE owner_id = ? AND status = "approved"',
    [ownerId]
  );
  return rows.length > 0 ? rows[0].id : null;
};

// 1.3.3 (2) ดึงข้อมูลร้านและแก้ไขข้อมูลร้านของตนเอง
export const getMyShop = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const ownerId = req.user!.id;
    const [rows] = await pool.execute<RowDataPacket[]>(
      `SELECT s.*, 
              (SELECT JSON_ARRAYAGG(JSON_OBJECT('id', id, 'image_url', image_url, 'is_cover', is_cover))
               FROM shop_images WHERE shop_id = s.id) AS images
       FROM shops s WHERE s.owner_id = ?`,
      [ownerId]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบข้อมูลร้านคาร์แคร์ของคุณ', 404);
      return;
    }

    sendSuccess(res, rows[0]);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลร้าน', 500, error);
  }
};

export const updateMyShop = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const ownerId = req.user!.id;
    const shopId = await getOwnerShopId(ownerId);
    if (!shopId) {
      sendError(res, 'ไม่พบร้านที่ได้รับอนุมัติของคุณ', 404);
      return;
    }

    const {
      shop_name,
      phone,
      description,
      address,
      latitude,
      longitude,
      open_time,
      close_time,
      accepts_motorcycle,
      accepts_car,
      accepts_suv,
      bank_name,
      bank_account_name,
      bank_account_number
    } = req.body;

    await pool.execute(
      `UPDATE shops SET
        shop_name = COALESCE(?, shop_name),
        phone = COALESCE(?, phone),
        description = COALESCE(?, description),
        address = COALESCE(?, address),
        latitude = COALESCE(?, latitude),
        longitude = COALESCE(?, longitude),
        open_time = COALESCE(?, open_time),
        close_time = COALESCE(?, close_time),
        accepts_motorcycle = COALESCE(?, accepts_motorcycle),
        accepts_car = COALESCE(?, accepts_car),
        accepts_suv = COALESCE(?, accepts_suv),
        bank_name = COALESCE(?, bank_name),
        bank_account_name = COALESCE(?, bank_account_name),
        bank_account_number = COALESCE(?, bank_account_number)
       WHERE id = ?`,
      [
        shop_name,
        phone,
        description,
        address,
        latitude,
        longitude,
        open_time,
        close_time,
        accepts_motorcycle !== undefined ? (accepts_motorcycle ? 1 : 0) : null,
        accepts_car !== undefined ? (accepts_car ? 1 : 0) : null,
        accepts_suv !== undefined ? (accepts_suv ? 1 : 0) : null,
        bank_name,
        bank_account_name,
        bank_account_number,
        shopId
      ]
    );

    sendSuccess(res, null, 'อัปเดตข้อมูลร้านเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการแก้ไขข้อมูลร้าน', 500, error);
  }
};

// 1.3.3 (3) จัดการวันให้บริการ (Operating Days)
export const getOperatingDays = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id, day_of_week, is_active FROM shop_operating_days WHERE shop_id = ?',
      [shopId]
    );
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

export const updateOperatingDays = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const { days } = req.body; // Array of { day_of_week, is_active }
    if (!Array.isArray(days)) {
      sendError(res, 'ข้อมูล days ไม่ถูกต้อง', 400);
      return;
    }

    for (const d of days) {
      await pool.execute(
        `INSERT INTO shop_operating_days (shop_id, day_of_week, is_active)
         VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE is_active = VALUES(is_active)`,
        [shopId, d.day_of_week, d.is_active ? 1 : 0]
      );
    }

    sendSuccess(res, null, 'อัปเดตวันให้บริการเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการบันทึกวันทำการ', 500, error);
  }
};

// 1.3.3 (4) จัดการสล็อตเวลา (Time Slots)
export const getTimeSlots = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id, start_time, end_time, capacity, vehicle_type, is_active FROM shop_time_slots WHERE shop_id = ? ORDER BY start_time ASC',
      [shopId]
    );
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

export const addTimeSlot = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const { start_time, end_time, capacity, vehicle_type } = req.body;
    if (!start_time || !end_time || !capacity) {
      sendError(res, 'กรุณาระบุช่วงเวลาและจำนวนคิวที่รับ', 400);
      return;
    }

    const [result] = await pool.execute<ResultSetHeader>(
      `INSERT INTO shop_time_slots (shop_id, start_time, end_time, capacity, vehicle_type, is_active)
       VALUES (?, ?, ?, ?, ?, TRUE)`,
      [shopId, start_time, end_time, capacity, vehicle_type || 'all']
    );

    sendSuccess(res, { id: result.insertId }, 'เพิ่มสล็อตเวลาให้บริการสำเร็จ', 201);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการเพิ่มสล็อตเวลา', 500, error);
  }
};

export const updateTimeSlot = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const slotId = req.params.id;
    const { start_time, end_time, capacity, vehicle_type, is_active } = req.body;

    await pool.execute(
      `UPDATE shop_time_slots SET
        start_time = COALESCE(?, start_time),
        end_time = COALESCE(?, end_time),
        capacity = COALESCE(?, capacity),
        vehicle_type = COALESCE(?, vehicle_type),
        is_active = COALESCE(?, is_active)
       WHERE id = ? AND shop_id = ?`,
      [start_time, end_time, capacity, vehicle_type, is_active, slotId, shopId]
    );

    sendSuccess(res, null, 'แก้ไขสล็อตเวลาเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

export const deleteTimeSlot = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const slotId = req.params.id;

    // ตรวจสอบว่าเคยมีการจองหรือไม่ ถ้ามีให้ปิดการใช้งานแทนการลบ
    const [bookings] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM bookings WHERE time_slot_id = ? LIMIT 1',
      [slotId]
    );

    if (bookings.length > 0) {
      await pool.execute('UPDATE shop_time_slots SET is_active = FALSE WHERE id = ? AND shop_id = ?', [
        slotId,
        shopId
      ]);
      sendSuccess(res, null, 'สล็อตนี้มีประวัติการจองแล้ว ระบบได้ทำการปิดการใช้งานแทนการลบ');
      return;
    }

    await pool.execute('DELETE FROM shop_time_slots WHERE id = ? AND shop_id = ?', [slotId, shopId]);
    sendSuccess(res, null, 'ลบสล็อตเวลาเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

// 1.3.3 (5) จัดการบริการและราคา (Services)
export const getServices = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id, name, vehicle_type, price, is_active FROM services WHERE shop_id = ? ORDER BY price ASC',
      [shopId]
    );
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

export const addService = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const { name, vehicle_type, price } = req.body;
    if (!name || !vehicle_type || !price) {
      sendError(res, 'กรุณาระบุชื่อบริการ ประเภทรถ และราคา', 400);
      return;
    }

    const [result] = await pool.execute<ResultSetHeader>(
      `INSERT INTO services (shop_id, name, vehicle_type, price, is_active)
       VALUES (?, ?, ?, ?, TRUE)`,
      [shopId, name, vehicle_type, price]
    );

    sendSuccess(res, { id: result.insertId }, 'เพิ่มบริการเรียบร้อยแล้ว', 201);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

export const updateService = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const serviceId = req.params.id;
    const { name, vehicle_type, price, is_active } = req.body;

    await pool.execute(
      `UPDATE services SET
        name = COALESCE(?, name),
        vehicle_type = COALESCE(?, vehicle_type),
        price = COALESCE(?, price),
        is_active = COALESCE(?, is_active)
       WHERE id = ? AND shop_id = ?`,
      [name, vehicle_type, price, is_active, serviceId, shopId]
    );

    sendSuccess(res, null, 'แก้ไขบริการเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

export const deleteService = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const serviceId = req.params.id;

    const [bookings] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM bookings WHERE service_id = ? LIMIT 1',
      [serviceId]
    );

    if (bookings.length > 0) {
      await pool.execute('UPDATE services SET is_active = FALSE WHERE id = ? AND shop_id = ?', [
        serviceId,
        shopId
      ]);
      sendSuccess(res, null, 'บริการนี้มีประวัติการจองแล้ว ระบบได้ทำการปิดการใช้งานแทนการลบ');
      return;
    }

    await pool.execute('DELETE FROM services WHERE id = ? AND shop_id = ?', [serviceId, shopId]);
    sendSuccess(res, null, 'ลบบริการเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

// 1.3.3 (6) ค้นหาข้อมูลการจองของร้าน (ตามวันที่ / สถานะ / ประเภทบริการ)
export const getShopBookings = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = await getOwnerShopId(req.user!.id);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const { date, status, service_id } = req.query;

    let query = `
      SELECT 
        b.id, b.booking_code, b.booking_date, b.status, b.payment_status,
        b.final_price, b.shop_share_amount, b.created_at,
        ts.start_time, ts.end_time,
        v.plate_number, v.vehicle_type, v.brand, v.model,
        srv.name AS service_name,
        u.full_name AS customer_name, u.phone AS customer_phone
      FROM bookings b
      JOIN shop_time_slots ts ON ts.id = b.time_slot_id
      JOIN vehicles v ON v.id = b.vehicle_id
      JOIN services srv ON srv.id = b.service_id
      JOIN users u ON u.id = b.user_id
      WHERE b.shop_id = ?
    `;

    const params: any[] = [shopId];

    if (date) {
      query += ` AND b.booking_date = ?`;
      params.push(date);
    }
    if (status) {
      query += ` AND b.status = ?`;
      params.push(status);
    }
    if (service_id) {
      query += ` AND b.service_id = ?`;
      params.push(service_id);
    }

    query += ` ORDER BY b.booking_date DESC, ts.start_time ASC`;

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงรายการจอง', 500, error);
  }
};

// 1.3.3 (7) อัปเดตสถานะการให้บริการ
// สถานะ: checked_in, in_service, completed, no_show
export const updateBookingStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const ownerId = req.user!.id;
    const shopId = await getOwnerShopId(ownerId);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const bookingId = req.params.id;
    const { status } = req.body;

    const validStatuses = ['checked_in', 'in_service', 'completed', 'no_show'];
    if (!validStatuses.includes(status)) {
      sendError(res, 'สถานะไม่ถูกต้อง (ต้องเป็น checked_in, in_service, completed หรือ no_show)', 400);
      return;
    }

    const [bookingRows] = await connection.execute<RowDataPacket[]>(
      `SELECT b.*, s.shop_name, u.id AS customer_id
       FROM bookings b
       JOIN shops s ON s.id = b.shop_id
       JOIN users u ON u.id = b.user_id
       WHERE b.id = ? AND b.shop_id = ?`,
      [bookingId, shopId]
    );

    if (bookingRows.length === 0) {
      sendError(res, 'ไม่พบรายการจองนี้', 404);
      return;
    }

    const booking = bookingRows[0];

    await connection.beginTransaction();

    await connection.execute('UPDATE bookings SET status = ? WHERE id = ?', [status, bookingId]);

    // เมื่อสถานะเป็น "completed" (บริการเสร็จสิ้น) หรือ "no_show" (ไม่มาตามนัด)
    // -> ปลดล็อกเงิน 95% จาก pending_balance เข้า balance กระเป๋าร้านจริง เพื่อให้ร้านถอนได้
    if ((status === 'completed' || status === 'no_show') && booking.payment_status === 'paid') {
      await connection.execute(
        `UPDATE wallets 
         SET pending_balance = pending_balance - ?,
             balance = balance + ?
         WHERE user_id = ?`,
        [booking.shop_share_amount, booking.shop_share_amount, ownerId]
      );

      await connection.execute(
        'UPDATE bookings SET payment_status = "released_to_shop" WHERE id = ?',
        [bookingId]
      );

      // บันทึก Log การเงิน
      const [walletRows] = await connection.execute<RowDataPacket[]>(
        'SELECT id FROM wallets WHERE user_id = ?',
        [ownerId]
      );
      if (walletRows.length > 0) {
        await connection.execute(
          `INSERT INTO wallet_transactions (wallet_id, amount, type, status, reference_id, notes)
           VALUES (?, ?, 'booking_earning', 'completed', ?, ?)`,
          [
            walletRows[0].id,
            booking.shop_share_amount,
            booking.booking_code,
            `รายได้จากคิว ${booking.booking_code} (หักค่าธรรมเนียมระบบ 5% แล้ว)`
          ]
        );
      }
    }

    await connection.commit();

    // 1.3.2 (12) ส่งการแจ้งเตือนถึงลูกค้าเมื่อบริการเสร็จสิ้น
    if (status === 'completed') {
      await createNotification(
        booking.customer_id,
        'บริการล้างรถเสร็จสิ้นแล้ว! 🎉',
        `รถของคุณที่ร้าน ${booking.shop_name} ล้างเสร็จเรียบร้อยแล้ว สามารถมารับรถและให้คะแนนรีวิวร้านค้าได้เลยครับ`,
        'service_completed',
        booking.id
      );
    }

    sendSuccess(res, null, `อัปเดตสถานะเป็น ${status} สำเร็จ`);
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการอัปเดตสถานะ', 500, error);
  } finally {
    connection.release();
  }
};

// 1.3.3 (9) ดูสรุปข้อมูลการจองและรายได้ของร้านตามช่วงเวลา
export const getShopStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const ownerId = req.user!.id;
    const shopId = await getOwnerShopId(ownerId);
    if (!shopId) {
      sendError(res, 'ไม่พบร้าน', 404);
      return;
    }

    const { start_date, end_date } = req.query;

    let query = `
      SELECT 
        COUNT(id) AS total_bookings,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_bookings,
        COUNT(CASE WHEN status = 'no_show' THEN 1 END) AS no_show_bookings,
        COUNT(CASE WHEN status LIKE 'cancelled%' THEN 1 END) AS cancelled_bookings,
        COALESCE(SUM(CASE WHEN status IN ('completed', 'no_show') THEN shop_share_amount ELSE 0 END), 0) AS total_revenue
      FROM bookings
      WHERE shop_id = ?
    `;

    const params: any[] = [shopId];

    if (start_date && end_date) {
      query += ` AND booking_date BETWEEN ? AND ?`;
      params.push(start_date, end_date);
    }

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows[0]);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลสถิติ', 500, error);
  }
};

// 1.3.3 (10) เจ้าของร้านส่งคำขอถอนเงิน Wallet ไปยังผู้ดูแลระบบ
export const requestOwnerWithdrawal = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const ownerId = req.user!.id;
    const { amount } = req.body;

    if (!amount || Number(amount) <= 0) {
      sendError(res, 'กรุณาระบุจำนวนเงินที่ต้องการถอนให้ถูกต้อง', 400);
      return;
    }

    // ดึง Wallet และข้อมูลบัญชีธนาคารของร้าน
    const [walletRows] = await connection.execute<RowDataPacket[]>(
      'SELECT id, balance FROM wallets WHERE user_id = ? FOR UPDATE',
      [ownerId]
    );

    if (walletRows.length === 0 || Number(walletRows[0].balance) < Number(amount)) {
      sendError(res, 'ยอดเงินคงเหลือในกระเป๋าไม่เพียงพอสำหรับการถอน', 400);
      return;
    }

    const [shopRows] = await connection.execute<RowDataPacket[]>(
      'SELECT bank_name, bank_account_name, bank_account_number FROM shops WHERE owner_id = ?',
      [ownerId]
    );

    if (shopRows.length === 0 || !shopRows[0].bank_account_number) {
      sendError(res, 'กรุณาระบุข้อมูลบัญชีธนาคารในเมนูข้อมูลร้านก่อนทำการถอนเงิน', 400);
      return;
    }

    const shop = shopRows[0];
    const walletId = walletRows[0].id;

    await connection.beginTransaction();

    // หักเงินออกจาก balance ชั่วคราวเพื่อรอการโอนจากแอดมิน
    await connection.execute('UPDATE wallets SET balance = balance - ? WHERE id = ?', [amount, walletId]);

    // สร้างคำขอถอนเงิน (status: pending)
    await connection.execute(
      `INSERT INTO withdrawal_requests (
        user_id, wallet_id, amount, bank_name, bank_account_name, bank_account_number, status
      ) VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [ownerId, walletId, amount, shop.bank_name, shop.bank_account_name, shop.bank_account_number]
    );

    await connection.commit();

    sendSuccess(res, null, 'ส่งคำขอถอนเงินเรียบร้อยแล้ว กรุณารอแอดมินตรวจสอบและโอนเงินเข้าบัญชี', 201);
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการส่งคำขอถอนเงิน', 500, error);
  } finally {
    connection.release();
  }
};
