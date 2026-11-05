import { Request, Response } from 'express';
import pool from '../config/database';
import { hashPassword, comparePassword } from '../utils/password';
import { generateToken } from '../utils/jwt';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../types';
import { ResultSetHeader, RowDataPacket } from 'mysql2';

// 1.3.1 (1) สมัครสมาชิกสำหรับผู้ใช้ทั่วไป
export const register = async (req: Request, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const { email, password, full_name, phone, vehicles } = req.body;

    if (!email || !password || !full_name || !phone) {
      sendError(res, 'กรุณากรอกข้อมูล Email, Password, ชื่อ-สกุล และ เบอร์โทรศัพท์ ให้ครบถ้วน', 400);
      return;
    }

    // ตรวจสอบ Email และ Phone ซ้ำ
    const [existing] = await connection.execute<RowDataPacket[]>(
      'SELECT id, email, phone FROM users WHERE email = ? OR phone = ?',
      [email, phone]
    );

    if (existing.length > 0) {
      if (existing[0].email === email) {
        sendError(res, 'อีเมลนี้ถูกใช้งานในระบบแล้ว', 400);
        return;
      }
      if (existing[0].phone === phone) {
        sendError(res, 'เบอร์โทรศัพท์นี้ถูกใช้งานในระบบแล้ว', 400);
        return;
      }
    }

    await connection.beginTransaction();

    // บันทึก User
    const hashedPassword = await hashPassword(password);
    const [userResult] = await connection.execute<ResultSetHeader>(
      `INSERT INTO users (email, password_hash, full_name, phone, role, status)
       VALUES (?, ?, ?, ?, 'member', 'active')`,
      [email, hashedPassword, full_name, phone]
    );
    const userId = userResult.insertId;

    // สร้างกระเป๋าเงิน (Wallet) เริ่มต้นให้กับสมาชิก
    await connection.execute(
      'INSERT INTO wallets (user_id, balance, pending_balance) VALUES (?, 0.00, 0.00)',
      [userId]
    );

    // บันทึกข้อมูลรถเริ่มต้นถ้ามีการส่งมา (รองรับ 1 คนหลายคัน)
    if (vehicles && Array.isArray(vehicles) && vehicles.length > 0) {
      for (const v of vehicles) {
        if (v.plate_number && v.vehicle_type) {
          await connection.execute(
            `INSERT INTO vehicles (user_id, plate_number, vehicle_type, brand, model)
             VALUES (?, ?, ?, ?, ?)`,
            [userId, v.plate_number, v.vehicle_type, v.brand || '-', v.model || '-']
          );
        }
      }
    }

    await connection.commit();

    const token = generateToken({
      id: userId,
      email,
      role: 'member',
      full_name
    });

    sendSuccess(
      res,
      {
        token,
        user: { id: userId, email, full_name, phone, role: 'member' }
      },
      'สมัครสมาชิกสำเร็จเรียบร้อยแล้ว',
      201
    );
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการสมัครสมาชิก', 500, error);
  } finally {
    connection.release();
  }
};

// 1.3.2 (1) & 1.3.3 (1) & 1.3.4 (1) เข้าสู่ระบบ
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      sendError(res, 'กรุณากรอก Email และ Password ให้ครบถ้วน', 400);
      return;
    }

    const [rows] = await pool.execute<RowDataPacket[]>(
      `SELECT u.id, u.email, u.password_hash, u.full_name, u.phone, u.role, u.status,
              s.id AS shop_id, s.status AS shop_status
       FROM users u
       LEFT JOIN shops s ON s.owner_id = u.id
       WHERE u.email = ?`,
      [email]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบอีเมลนี้ในระบบหรือรหัสผ่านไม่ถูกต้อง', 401);
      return;
    }

    const user = rows[0];

    // ตรวจสอบสถานะบัญชี
    if (user.status === 'suspended') {
      sendError(res, 'บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ', 403);
      return;
    }

    // กรณีเป็นเจ้าของร้าน ต้องได้รับการอนุมัติก่อน (1.3.3 ข้อ 1)
    if (user.role === 'owner') {
      if (!user.shop_status || user.shop_status === 'pending') {
        sendError(res, 'บัญชีร้านคาร์แคร์ของคุณกำลังรอการอนุมัติจากผู้ดูแลระบบ', 403);
        return;
      }
      if (user.shop_status === 'rejected') {
        sendError(res, 'คำขอเปิดร้านของคุณไม่ผ่านการอนุมัติ กรุณาติดต่อฝ่ายสนับสนุน', 403);
        return;
      }
      if (user.shop_status === 'suspended') {
        sendError(res, 'ร้านของคุณถูกระงับการให้บริการชั่วคราว', 403);
        return;
      }
    }

    const isMatch = await comparePassword(password, user.password_hash);
    if (!isMatch) {
      sendError(res, 'รหัสผ่านไม่ถูกต้อง', 401);
      return;
    }

    const token = generateToken({
      id: user.id,
      email: user.email,
      role: user.role,
      full_name: user.full_name
    });

    sendSuccess(
      res,
      {
        token,
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          phone: user.phone,
          role: user.role,
          shop_id: user.shop_id || null
        }
      },
      'เข้าสู่ระบบสำเร็จ'
    );
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ', 500, error);
  }
};

// 1.3.2 (2) เข้าสู่ระบบด้วย Google Account
export const googleAuth = async (req: Request, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const { google_id, email, full_name, phone, vehicles } = req.body;

    if (!google_id || !email) {
      sendError(res, 'ข้อมูล Google Account ไม่ครบถ้วน', 400);
      return;
    }

    const [rows] = await connection.execute<RowDataPacket[]>(
      'SELECT id, email, full_name, phone, role, status FROM users WHERE google_id = ? OR email = ?',
      [google_id, email]
    );

    if (rows.length > 0) {
      const user = rows[0];
      if (user.status === 'suspended') {
        sendError(res, 'บัญชีของคุณถูกระงับการใช้งาน', 403);
        return;
      }

      // อัปเดต google_id หากยังไม่มี
      await connection.execute('UPDATE users SET google_id = ? WHERE id = ?', [google_id, user.id]);

      const token = generateToken({
        id: user.id,
        email: user.email,
        role: user.role,
        full_name: user.full_name
      });

      sendSuccess(res, { token, user }, 'เข้าสู่ระบบด้วย Google สำเร็จ');
      return;
    }

    // กรณีเข้าใช้งานครั้งแรก ต้องกรอกข้อมูลเพิ่มเติม (1.3.2 ข้อ 2)
    if (!phone || !full_name) {
      sendSuccess(
        res,
        { is_new_user: true, email, full_name, google_id },
        'กรุณากรอกข้อมูลเพิ่มเติม (ชื่อ-สกุล, เบอร์โทร และรถ) สำหรับการเข้าใช้งานครั้งแรก'
      );
      return;
    }

    await connection.beginTransaction();

    const [insertResult] = await connection.execute<ResultSetHeader>(
      `INSERT INTO users (email, full_name, phone, google_id, role, status)
       VALUES (?, ?, ?, ?, 'member', 'active')`,
      [email, full_name, phone, google_id]
    );
    const userId = insertResult.insertId;

    // สร้าง Wallet
    await connection.execute(
      'INSERT INTO wallets (user_id, balance, pending_balance) VALUES (?, 0.00, 0.00)',
      [userId]
    );

    // บันทึกรถ
    if (vehicles && Array.isArray(vehicles)) {
      for (const v of vehicles) {
        if (v.plate_number && v.vehicle_type) {
          await connection.execute(
            `INSERT INTO vehicles (user_id, plate_number, vehicle_type, brand, model)
             VALUES (?, ?, ?, ?, ?)`,
            [userId, v.plate_number, v.vehicle_type, v.brand || '-', v.model || '-']
          );
        }
      }
    }

    await connection.commit();

    const token = generateToken({
      id: userId,
      email,
      role: 'member',
      full_name
    });

    sendSuccess(
      res,
      {
        token,
        user: { id: userId, email, full_name, phone, role: 'member' }
      },
      'ลงทะเบียนและเข้าสู่ระบบด้วย Google สำเร็จ',
      201
    );
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการยืนยันตัวตนด้วย Google', 500, error);
  } finally {
    connection.release();
  }
};

// 1.3.2 (3) กู้คืนรหัสผ่านผ่านทางอีเมล (ส่ง OTP)
export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;
    if (!email) {
      sendError(res, 'กรุณาระบุอีเมล', 400);
      return;
    }

    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบอีเมลนี้ในระบบ', 404);
      return;
    }

    // สร้างรหัส OTP 6 หลัก
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // หมดอายุใน 15 นาที

    await pool.execute(
      'INSERT INTO password_resets (email, otp_code, expires_at) VALUES (?, ?, ?)',
      [email, otpCode, expiresAt]
    );

    // ในการส่งจริงจะส่งผ่าน Nodemailer / SendGrid
    // จำลองส่งรหัสกลับมาใน response เพื่อให้ทดสอบได้ง่าย
    sendSuccess(
      res,
      { otp_code_demo: otpCode, expires_in_minutes: 15 },
      `รหัส OTP สำหรับรีเซ็ตรหัสผ่านถูกส่งไปยัง ${email} เรียบร้อยแล้ว`
    );
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการส่ง OTP', 500, error);
  }
};

// 1.3.2 (3) ยืนยันรหัส OTP และตั้งรหัสผ่านใหม่
export const resetPasswordWithOtp = async (req: Request, res: Response): Promise<void> => {
  const connection = await pool.getConnection();
  try {
    const { email, otp_code, new_password } = req.body;

    if (!email || !otp_code || !new_password) {
      sendError(res, 'กรุณาระบุ email, otp_code และ new_password', 400);
      return;
    }

    const [rows] = await connection.execute<RowDataPacket[]>(
      `SELECT id FROM password_resets
       WHERE email = ? AND otp_code = ? AND is_used = FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [email, otp_code]
    );

    if (rows.length === 0) {
      sendError(res, 'รหัส OTP ไม่ถูกต้องหรือหมดอายุแล้ว', 400);
      return;
    }

    const resetId = rows[0].id;
    const newHash = await hashPassword(new_password);

    await connection.beginTransaction();

    await connection.execute('UPDATE users SET password_hash = ? WHERE email = ?', [newHash, email]);
    await connection.execute('UPDATE password_resets SET is_used = TRUE WHERE id = ?', [resetId]);

    await connection.commit();

    sendSuccess(res, null, 'ตั้งรหัสผ่านใหม่สำเร็จแล้ว สามารถเข้าสู่ระบบด้วยรหัสผ่านใหม่ได้ทันที');
  } catch (error) {
    await connection.rollback();
    sendError(res, 'เกิดข้อผิดพลาดในการตั้งรหัสผ่านใหม่', 500, error);
  } finally {
    connection.release();
  }
};

// ดึงข้อมูลโปรไฟล์ของฉัน (Current User Profile + Wallet)
export const getMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;

    const [userRows] = await pool.execute<RowDataPacket[]>(
      `SELECT u.id, u.email, u.full_name, u.phone, u.role, u.status,
              w.balance, w.pending_balance,
              s.id AS shop_id, s.shop_name, s.status AS shop_status
       FROM users u
       LEFT JOIN wallets w ON w.user_id = u.id
       LEFT JOIN shops s ON s.owner_id = u.id
       WHERE u.id = ?`,
      [userId]
    );

    if (userRows.length === 0) {
      sendError(res, 'ไม่พบข้อมูลผู้ใช้', 404);
      return;
    }

    const [vehicles] = await pool.execute<RowDataPacket[]>(
      'SELECT id, plate_number, vehicle_type, brand, model FROM vehicles WHERE user_id = ?',
      [userId]
    );

    sendSuccess(res, {
      ...userRows[0],
      vehicles
    });
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลส่วนตัว', 500, error);
  }
};
