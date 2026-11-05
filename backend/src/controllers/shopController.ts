import { Request, Response } from 'express';
import pool from '../config/database';
import { hashPassword } from '../utils/password';
import { sendSuccess, sendError } from '../utils/response';
import { ResultSetHeader, RowDataPacket } from 'mysql2';

// 1.3.1 (4) สมัครเป็นร้านล้างรถ
export const registerShop = async (req: Request, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const {
      email,
      password,
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

    const files = req.files as { [fieldname: string]: Express.Multer.File[] };
    const idCardFile = files && files['id_card'] ? files['id_card'][0] : null;
    const shopImageFiles = files && files['shop_images'] ? files['shop_images'] : [];

    // ตรวจสอบความครบถ้วน
    if (
      !email ||
      !password ||
      !shop_name ||
      !phone ||
      !address ||
      !latitude ||
      !longitude ||
      !open_time ||
      !close_time ||
      !bank_name ||
      !bank_account_name ||
      !bank_account_number
    ) {
      sendError(res, 'กรุณากรอกข้อมูลการสมัครร้านค้าให้ครบถ้วนทุกช่อง', 400);
      return;
    }

    if (!idCardFile) {
      sendError(res, 'กรุณาอัปโหลดสำเนาบัตรประชาชนเพื่อยืนยันตัวตนตามกฎหมาย PDPA', 400);
      return;
    }

    if (shopImageFiles.length < 3) {
      sendError(res, 'กรุณาอัปโหลดรูปถ่ายหน้าร้านอย่างน้อย 3 รูป', 400);
      return;
    }

    // ตรวจสอบ Email ซ้ำ
    const [existing] = await connection.execute<RowDataPacket[]>(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );
    if (existing.length > 0) {
      sendError(res, 'อีเมลนี้ถูกใช้งานในระบบแล้ว', 400);
      return;
    }

    await connection.beginTransaction();

    // 1. สร้างบัญชีผู้ใช้ Role: 'owner'
    const hashedPassword = await hashPassword(password);
    const [userResult] = await connection.execute<ResultSetHeader>(
      `INSERT INTO users (email, password_hash, full_name, phone, role, status)
       VALUES (?, ?, ?, ?, 'owner', 'active')`,
      [email, hashedPassword, shop_name, phone]
    );
    const ownerId = userResult.insertId;

    // 2. สร้างกระเป๋าเงิน Wallet ให้ร้านค้า
    await connection.execute(
      'INSERT INTO wallets (user_id, balance, pending_balance) VALUES (?, 0.00, 0.00)',
      [ownerId]
    );

    // 3. บันทึกข้อมูลร้านค้า (สถานะ: pending)
    const [shopResult] = await connection.execute<ResultSetHeader>(
      `INSERT INTO shops (
        owner_id, shop_name, phone, description, address,
        latitude, longitude, open_time, close_time,
        accepts_motorcycle, accepts_car, accepts_suv,
        id_card_image_url, bank_name, bank_account_name, bank_account_number, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [
        ownerId,
        shop_name,
        phone,
        description || null,
        address,
        latitude,
        longitude,
        open_time,
        close_time,
        accepts_motorcycle === 'true' || accepts_motorcycle === true ? 1 : 0,
        accepts_car === 'true' || accepts_car === true ? 1 : 0,
        accepts_suv === 'true' || accepts_suv === true ? 1 : 0,
        idCardFile.path.replace(/\\/g, '/'),
        bank_name,
        bank_account_name,
        bank_account_number
      ]
    );
    const shopId = shopResult.insertId;

    // 4. บันทึกรูปถ่ายหน้าร้าน (≥ 3 รูป)
    for (let i = 0; i < shopImageFiles.length; i++) {
      await connection.execute(
        `INSERT INTO shop_images (shop_id, image_url, is_cover) VALUES (?, ?, ?)`,
        [shopId, shopImageFiles[i].path.replace(/\\/g, '/'), i === 0 ? 1 : 0]
      );
    }

    // 5. ค่าเริ่มต้นวันเปิดทำการ (จันทร์ - เสาร์)
    const defaultDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    for (const day of defaultDays) {
      await connection.execute(
        'INSERT INTO shop_operating_days (shop_id, day_of_week, is_active) VALUES (?, ?, TRUE)',
        [shopId, day]
      );
    }

    await connection.commit();

    sendSuccess(
      res,
      { shop_id: shopId, owner_id: ownerId },
      'ส่งคำขอเปิดร้านล้างรถสำเร็จแล้ว กรุณารอผู้ดูแลระบบตรวจสอบและอนุมัติ',
      201
    );
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการลงทะเบียนร้านล้างรถ', 500, error);
  } finally {
    connection.release();
  }
};

// 1.3.1 (2, 3) & 1.3.2 (5) ค้นหาร้านล้างรถ แสดงบนแผนที่ & ตัวกรอง
export const searchShops = async (req: Request, res: Response): Promise<void> => {
  try {
    const { keyword, service_name, vehicle_type, user_lat, user_lng, min_rating, max_distance_km } = req.query;

    let query = `
      SELECT 
        s.id, s.shop_name, s.phone, s.description, s.address,
        s.latitude, s.longitude, s.open_time, s.close_time,
        s.accepts_motorcycle, s.accepts_car, s.accepts_suv,
        COALESCE(AVG(r.rating), 0) AS average_rating,
        COUNT(DISTINCT r.id) AS review_count,
        (SELECT image_url FROM shop_images WHERE shop_id = s.id AND is_cover = TRUE LIMIT 1) AS cover_image
    `;

    // ถ้ามีพิกัดปัจจุบัน ให้คำนวณระยะทางด้วย Haversine Formula (หน่วย: กิโลเมตร)
    if (user_lat && user_lng) {
      query += `,
        (6371 * acos(
          cos(radians(?)) * cos(radians(s.latitude)) *
          cos(radians(s.longitude) - radians(?)) +
          sin(radians(?)) * sin(radians(s.latitude))
        )) AS distance_km
      `;
    }

    query += `
      FROM shops s
      LEFT JOIN reviews r ON r.shop_id = s.id
      LEFT JOIN services srv ON srv.shop_id = s.id AND srv.is_active = TRUE
      WHERE s.status = 'approved'
    `;

    const params: any[] = [];
    if (user_lat && user_lng) {
      params.push(Number(user_lat), Number(user_lng), Number(user_lat));
    }

    if (keyword) {
      query += ` AND (s.shop_name LIKE ? OR s.description LIKE ?)`;
      params.push(`%${keyword}%`, `%${keyword}%`);
    }

    if (service_name) {
      query += ` AND srv.name LIKE ?`;
      params.push(`%${service_name}%`);
    }

    if (vehicle_type) {
      if (vehicle_type === 'motorcycle') query += ` AND s.accepts_motorcycle = TRUE`;
      if (vehicle_type === 'car') query += ` AND s.accepts_car = TRUE`;
      if (vehicle_type === 'suv') query += ` AND s.accepts_suv = TRUE`;
    }

    query += ` GROUP BY s.id`;

    // กรองคะแนนรีวิว หรือระยะทาง
    if (min_rating) {
      query += ` HAVING average_rating >= ?`;
      params.push(Number(min_rating));
    }

    if (user_lat && user_lng && max_distance_km) {
      query += min_rating ? ` AND distance_km <= ?` : ` HAVING distance_km <= ?`;
      params.push(Number(max_distance_km));
    }

    // จัดเรียง
    if (user_lat && user_lng) {
      query += ` ORDER BY distance_km ASC`;
    } else {
      query += ` ORDER BY average_rating DESC, s.id DESC`;
    }

    const [rows] = await pool.execute<RowDataPacket[]>(query, params);
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการค้นหาร้านล้างรถ', 500, error);
  }
};

// ดูข้อมูลร้านล้างรถโดยละเอียด (Services, Operating Days, Images, Reviews)
export const getShopDetail = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.params.id;

    // ข้อมูลร้านหลัก
    const [shops] = await pool.execute<RowDataPacket[]>(
      `SELECT s.id, s.shop_name, s.phone, s.description, s.address,
              s.latitude, s.longitude, s.open_time, s.close_time,
              s.accepts_motorcycle, s.accepts_car, s.accepts_suv,
              COALESCE(AVG(r.rating), 0) AS average_rating,
              COUNT(DISTINCT r.id) AS review_count
       FROM shops s
       LEFT JOIN reviews r ON r.shop_id = s.id
       WHERE s.id = ? AND s.status = 'approved'
       GROUP BY s.id`,
      [shopId]
    );

    if (shops.length === 0) {
      sendError(res, 'ไม่พบร้านล้างรถนี้หรือร้านยังไม่ได้รับการอนุมัติ', 404);
      return;
    }

    const shop = shops[0];

    // รูปถ่ายร้าน
    const [images] = await pool.execute<RowDataPacket[]>(
      'SELECT id, image_url, is_cover FROM shop_images WHERE shop_id = ?',
      [shopId]
    );

    // วันเปิดทำการ
    const [operatingDays] = await pool.execute<RowDataPacket[]>(
      'SELECT day_of_week, is_active FROM shop_operating_days WHERE shop_id = ? AND is_active = TRUE',
      [shopId]
    );

    // บริการและราคา
    const [services] = await pool.execute<RowDataPacket[]>(
      'SELECT id, name, vehicle_type, price FROM services WHERE shop_id = ? AND is_active = TRUE ORDER BY price ASC',
      [shopId]
    );

    // สล็อตเวลา
    const [timeSlots] = await pool.execute<RowDataPacket[]>(
      'SELECT id, start_time, end_time, capacity, vehicle_type FROM shop_time_slots WHERE shop_id = ? AND is_active = TRUE ORDER BY start_time ASC',
      [shopId]
    );

    // รีวิว 10 รายการล่าสุด
    const [recentReviews] = await pool.execute<RowDataPacket[]>(
      `SELECT r.id, r.rating, r.comment, r.created_at, u.full_name AS reviewer_name
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       WHERE r.shop_id = ?
       ORDER BY r.created_at DESC LIMIT 10`,
      [shopId]
    );

    sendSuccess(res, {
      ...shop,
      images,
      operating_days: operatingDays,
      services,
      time_slots: timeSlots,
      reviews: recentReviews
    });
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลร้านล้างรถ', 500, error);
  }
};

// 1.3.1 (2) สล็อตเวลาและจำนวนคิวว่างในวันที่ระบุ
export const getAvailableSlots = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.params.id;
    const { date, vehicle_type } = req.query;

    if (!date) {
      sendError(res, 'กรุณาระบุวันที่ที่ต้องการจอง (date: YYYY-MM-DD)', 400);
      return;
    }

    // หาวันในสัปดาห์ เช่น 'monday'
    const targetDate = new Date(date as string);
    const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const dayOfWeek = dayNames[targetDate.getDay()];

    // ตรวจสอบว่าร้านเปิดทำการในวันนี้หรือไม่
    const [openDay] = await pool.execute<RowDataPacket[]>(
      'SELECT is_active FROM shop_operating_days WHERE shop_id = ? AND day_of_week = ? AND is_active = TRUE',
      [shopId, dayOfWeek]
    );

    if (openDay.length === 0) {
      sendSuccess(res, { is_open: false, message: 'ร้านปิดให้บริการในวันนี้', slots: [] });
      return;
    }

    // ดึงสล็อตทั้งหมดของร้าน พร้อมคำนวณจำนวนที่ถูกจองแล้วในวันที่ระบุ
    let slotQuery = `
      SELECT 
        ts.id, ts.start_time, ts.end_time, ts.capacity, ts.vehicle_type,
        COUNT(b.id) AS booked_count,
        (ts.capacity - COUNT(b.id)) AS available_count
      FROM shop_time_slots ts
      LEFT JOIN bookings b ON b.time_slot_id = ts.id 
                          AND b.booking_date = ? 
                          AND b.status NOT IN ('cancelled_by_user', 'cancelled_by_shop')
      WHERE ts.shop_id = ? AND ts.is_active = TRUE
    `;

    const params: any[] = [date, shopId];

    if (vehicle_type) {
      slotQuery += ` AND (ts.vehicle_type = 'all' OR ts.vehicle_type = ?)`;
      params.push(vehicle_type);
    }

    slotQuery += ` GROUP BY ts.id ORDER BY ts.start_time ASC`;

    const [slots] = await pool.execute<RowDataPacket[]>(slotQuery, params);

    const formattedSlots = slots.map((s) => ({
      id: s.id,
      start_time: s.start_time,
      end_time: s.end_time,
      capacity: s.capacity,
      vehicle_type: s.vehicle_type,
      booked_count: Number(s.booked_count),
      available_count: Math.max(0, Number(s.available_count)),
      is_available: Number(s.available_count) > 0
    }));

    sendSuccess(res, {
      is_open: true,
      booking_date: date,
      day_of_week: dayOfWeek,
      slots: formattedSlots
    });
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการตรวจสอบสล็อตเวลา', 500, error);
  }
};
