import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { createNotification } from '../utils/notification';
import { AuthRequest } from '../types';
import { ResultSetHeader, RowDataPacket } from 'mysql2';

// 1.3.2 (6) จองคิวล้างรถ (พร้อมหักเงินจาก Wallet และแบ่ง 95% เข้า Escrow ร้าน)
export const createBooking = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user!.id;
    const { shop_id, vehicle_id, service_id, time_slot_id, booking_date, discount_code } = req.body;

    if (!shop_id || !vehicle_id || !service_id || !time_slot_id || !booking_date) {
      sendError(res, 'กรุณาระบุข้อมูลการจองให้ครบถ้วน (shop, vehicle, service, time_slot, date)', 400);
      return;
    }

    // วันที่จองต้องไม่เป็นอดีต
    const today = new Date().toISOString().split('T')[0];
    if (booking_date < today) {
      sendError(res, 'ไม่สามารถเลือกวันที่ในอดีตได้', 400);
      return;
    }

    await connection.beginTransaction();

    // 1. ตรวจสอบข้อมูลรถของผู้ใช้
    const [vehicles] = await connection.execute<RowDataPacket[]>(
      'SELECT id, plate_number, vehicle_type FROM vehicles WHERE id = ? AND user_id = ?',
      [vehicle_id, userId]
    );
    if (vehicles.length === 0) {
      await connection.rollback();
      sendError(res, 'ไม่พบข้อมูลรถของคุณ', 404);
      return;
    }
    const vehicle = vehicles[0];

    // 2. ตรวจสอบบริการและราคา
    const [services] = await connection.execute<RowDataPacket[]>(
      'SELECT id, name, price, vehicle_type FROM services WHERE id = ? AND shop_id = ? AND is_active = TRUE',
      [service_id, shop_id]
    );
    if (services.length === 0) {
      await connection.rollback();
      sendError(res, 'บริการที่เลือกไม่พร้อมให้บริการ', 404);
      return;
    }
    const service = services[0];

    // 3. ตรวจสอบสล็อตเวลาและจำนวนคิวว่าง (Lock for Update)
    const [slots] = await connection.execute<RowDataPacket[]>(
      `SELECT ts.*, s.owner_id, s.shop_name
       FROM shop_time_slots ts
       JOIN shops s ON s.id = ts.shop_id
       WHERE ts.id = ? AND ts.shop_id = ? AND ts.is_active = TRUE
       FOR UPDATE`,
      [time_slot_id, shop_id]
    );
    if (slots.length === 0) {
      await connection.rollback();
      sendError(res, 'ไม่พบสล็อตเวลาที่เลือก', 404);
      return;
    }
    const slot = slots[0];

    // ตรวจสอบจำนวนคิวที่ถูกจองแล้วในสล็อตนี้ ณ วันที่ดังกล่าว
    const [bookedRows] = await connection.execute<RowDataPacket[]>(
      `SELECT COUNT(id) AS booked_count FROM bookings
       WHERE time_slot_id = ? AND booking_date = ? AND status NOT IN ('cancelled_by_user', 'cancelled_by_shop')`,
      [time_slot_id, booking_date]
    );

    const bookedCount = bookedRows[0].booked_count;
    if (bookedCount >= slot.capacity) {
      await connection.rollback();
      sendError(res, 'สล็อตเวลาเต็มแล้ว กรุณาเลือกสล็อตเวลาอื่น', 400);
      return;
    }

    // 4. คำนวณส่วนลด (ถ้ามี)
    let discountAmount = 0.00;
    let discountId: number | null = null;
    const originalPrice = Number(service.price);

    if (discount_code) {
      const [discounts] = await connection.execute<RowDataPacket[]>(
        'SELECT id, discount_percent FROM discounts WHERE code = ? AND is_active = TRUE',
        [discount_code]
      );
      if (discounts.length > 0) {
        discountId = discounts[0].id;
        const percent = Number(discounts[0].discount_percent);
        discountAmount = (originalPrice * percent) / 100;
      }
    }

    const finalPrice = Math.max(0, originalPrice - discountAmount);
    // แบ่งเงิน: 95% เข้าร้านค้า, 5% เป็นค่าธรรมเนียมระบบ
    const shopShareAmount = Number((finalPrice * 0.95).toFixed(2));
    const systemFeeAmount = Number((finalPrice - shopShareAmount).toFixed(2));

    // 5. ตรวจสอบยอดเงินในกระเป๋า Wallet ของลูกค้า (Lock for Update)
    const [wallets] = await connection.execute<RowDataPacket[]>(
      'SELECT id, balance FROM wallets WHERE user_id = ? FOR UPDATE',
      [userId]
    );

    if (wallets.length === 0 || Number(wallets[0].balance) < finalPrice) {
      await connection.rollback();
      sendError(
        res,
        `ยอดเงินคงเหลือใน Wallet ไม่เพียงพอ (ต้องการ ${finalPrice} บาท แต่มี ${wallets[0]?.balance || 0} บาท) กรุณาเติมเงินก่อนทำรายการ`,
        400
      );
      return;
    }

    const userWalletId = wallets[0].id;
    const shopOwnerId = slot.owner_id;

    // 6. ตัดเงินจาก Wallet ลูกค้า
    await connection.execute('UPDATE wallets SET balance = balance - ? WHERE id = ?', [
      finalPrice,
      userWalletId
    ]);

    // 7. นำเงิน 95% พักไว้ใน pending_balance ของร้านค้า (Escrow)
    await connection.execute(
      'UPDATE wallets SET pending_balance = pending_balance + ? WHERE user_id = ?',
      [shopShareAmount, shopOwnerId]
    );

    // 8. สร้าง Booking Code (เช่น WQ20261105-XXXX)
    const bookingCode = `WQ-${Date.now().toString().slice(-6)}-${Math.floor(100 + Math.random() * 900)}`;

    // 9. บันทึกข้อมูลการจอง
    const [bookingResult] = await connection.execute<ResultSetHeader>(
      `INSERT INTO bookings (
        booking_code, user_id, shop_id, vehicle_id, service_id, time_slot_id, discount_id,
        booking_date, original_price, discount_amount, final_price,
        shop_share_amount, system_fee_amount, status, payment_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending_service', 'paid')`,
      [
        bookingCode,
        userId,
        shop_id,
        vehicle_id,
        service_id,
        time_slot_id,
        discountId,
        booking_date,
        originalPrice,
        discountAmount,
        finalPrice,
        shopShareAmount,
        systemFeeAmount
      ]
    );
    const bookingId = bookingResult.insertId;

    // 10. บันทึก Transaction การชำระเงินของลูกค้า
    await connection.execute(
      `INSERT INTO wallet_transactions (wallet_id, amount, type, status, reference_id, notes)
       VALUES (?, ?, 'booking_payment', 'completed', ?, ?)`,
      [
        userWalletId,
        finalPrice,
        bookingCode,
        `ชำระค่าบริการล้างรถ ${service.name} ที่ร้าน ${slot.shop_name}`
      ]
    );

    await connection.commit();

    // 1.3.3 (8) ส่งการแจ้งเตือนไปยังเจ้าของร้านเมื่อมีลูกค้าจองคิวใหม่
    await createNotification(
      shopOwnerId,
      'มีรายการจองคิวใหม่! 🚗',
      `คิวใหม่รหัส ${bookingCode} นัดหมายวันที่ ${booking_date} เวลา ${slot.start_time} - ${slot.end_time} (${service.name})`,
      'booking_confirmed',
      bookingId
    );

    sendSuccess(
      res,
      {
        booking_id: bookingId,
        booking_code: bookingCode,
        final_price: finalPrice,
        status: 'pending_service'
      },
      'จองคิวและชำระเงินเรียบร้อยแล้ว',
      201
    );
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการจองคิว', 500, error);
  } finally {
    connection.release();
  }
};

// 1.3.2 (9) ดูประวัติการจองและสถานะการจองของสมาชิก
export const getMyBookings = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { status } = req.query;

    let query = `
      SELECT 
        b.id, b.booking_code, b.booking_date, b.status, b.payment_status,
        b.original_price, b.discount_amount, b.final_price, b.created_at,
        s.id AS shop_id, s.shop_name, s.phone AS shop_phone, s.address AS shop_address,
        ts.start_time, ts.end_time,
        v.plate_number, v.vehicle_type, v.brand, v.model,
        srv.name AS service_name,
        r.id AS review_id, r.rating AS my_rating
      FROM bookings b
      JOIN shops s ON s.id = b.shop_id
      JOIN shop_time_slots ts ON ts.id = b.time_slot_id
      JOIN vehicles v ON v.id = b.vehicle_id
      JOIN services srv ON srv.id = b.service_id
      LEFT JOIN reviews r ON r.booking_id = b.id
      WHERE b.user_id = ?
    `;

    const params: any[] = [userId];

    if (status) {
      query += ` AND b.status = ?`;
      params.push(status);
    }

    query += ` ORDER BY b.booking_date DESC, ts.start_time DESC`;

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงประวัติการจอง', 500, error);
  }
};

// 1.3.2 (8) ยกเลิกการจองก่อนเวลาเข้ารับบริการอย่างน้อย 24 ชั่วโมง ได้รับเงินคืนเต็มจำนวน
export const cancelBooking = async (req: AuthRequest, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user!.id;
    const bookingId = req.params.id;

    const [rows] = await connection.execute<RowDataPacket[]>(
      `SELECT b.*, ts.start_time, s.owner_id, s.shop_name
       FROM bookings b
       JOIN shop_time_slots ts ON ts.id = b.time_slot_id
       JOIN shops s ON s.id = b.shop_id
       WHERE b.id = ? AND b.user_id = ?`,
      [bookingId, userId]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบรายการจองนี้หรือคุณไม่มีสิทธิ์ยกเลิก', 404);
      return;
    }

    const booking = rows[0];

    if (booking.status !== 'pending_service') {
      sendError(res, 'ไม่สามารถยกเลิกรายการนี้ได้เนื่องจากสถานะปัจจุบันไม่อยู่ในเงื่อนไข', 400);
      return;
    }

    // คำนวณเวลาที่เหลือก่อนเข้ารับบริการ
    // รูปแบบวันและเวลา: YYYY-MM-DDTHH:mm:ss
    const appointmentDateTimeStr = `${booking.booking_date.toISOString().split('T')[0]}T${booking.start_time}`;
    const appointmentTime = new Date(appointmentDateTimeStr).getTime();
    const now = Date.now();
    const diffHours = (appointmentTime - now) / (1000 * 60 * 60);

    if (diffHours < 24) {
      sendError(
        res,
        'ไม่สามารถยกเลิกได้ เนื่องจากต้องยกเลิกล่วงหน้าอย่างน้อย 24 ชั่วโมงก่อนถึงเวลานัดหมาย',
        400
      );
      return;
    }

    await connection.beginTransaction();

    // 1. ปรับสถานะการจองเป็น cancelled_by_user และ payment_status เป็น refunded
    await connection.execute(
      'UPDATE bookings SET status = "cancelled_by_user", payment_status = "refunded" WHERE id = ?',
      [bookingId]
    );

    // 2. คืนเงินเต็มจำนวนเข้ากระเป๋าของลูกค้า
    await connection.execute(
      'UPDATE wallets SET balance = balance + ? WHERE user_id = ?',
      [booking.final_price, userId]
    );

    // 3. ดึงเงินส่วนแบ่ง 95% ออกจาก pending_balance ของร้านค้า
    await connection.execute(
      'UPDATE wallets SET pending_balance = GREATEST(0, pending_balance - ?) WHERE user_id = ?',
      [booking.shop_share_amount, booking.owner_id]
    );

    // 4. บันทึก Transaction การคืนเงิน
    const [userWallet] = await connection.execute<RowDataPacket[]>(
      'SELECT id FROM wallets WHERE user_id = ?',
      [userId]
    );
    if (userWallet.length > 0) {
      await connection.execute(
        `INSERT INTO wallet_transactions (wallet_id, amount, type, status, reference_id, notes)
         VALUES (?, ?, 'refund', 'completed', ?, ?)`,
        [
          userWallet[0].id,
          booking.final_price,
          booking.booking_code,
          `คืนเงินเต็มจำนวนจากการยกเลิกคิว ${booking.booking_code}`
        ]
      );
    }

    await connection.commit();

    // 1.3.3 (8) ส่งการแจ้งเตือนไปยังเจ้าของร้านว่ามีการยกเลิกคิว
    await createNotification(
      booking.owner_id,
      'ลูกค้ายกเลิกคิวล้างรถ ⚠️',
      `คิวรหัส ${booking.booking_code} ในวันที่ ${booking.booking_date.toISOString().split('T')[0]} ถูกยกเลิกโดยลูกค้า สล็อตเวลาได้ถูกเปิดว่างให้ผู้อื่นแล้ว`,
      'booking_cancelled',
      booking.id
    );

    sendSuccess(res, null, 'ยกเลิกการจองสำเร็จ และระบบได้คืนเงินเข้ากระเป๋าของคุณเต็มจำนวนแล้ว');
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการยกเลิกการจอง', 500, error);
  } finally {
    connection.release();
  }
};
