import { Response, NextFunction } from 'express';
import { AuthRequest, UserPayload, UserRole } from '../types';
import { verifyToken } from '../utils/jwt';
import { sendError } from '../utils/response';
import pool from '../config/database';
import { RowDataPacket } from 'mysql2';

export const authenticateToken = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

  if (!token) {
    sendError(res, 'กรุณาเข้าสู่ระบบก่อนทำรายการ (Token required)', 401);
    return;
  }

  try {
    const decoded = verifyToken(token) as UserPayload;

    // ตรวจสอบว่าบัญชีถูกระงับการใช้งานหรือไม่ (1.3.4 ข้อ 3)
    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id, status, role FROM users WHERE id = ?',
      [decoded.id]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบข้อมูลบัญชีผู้ใช้นี้ในระบบ', 404);
      return;
    }

    if (rows[0].status === 'suspended') {
      sendError(res, 'บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ', 403);
      return;
    }

    req.user = {
      id: decoded.id,
      email: decoded.email,
      role: rows[0].role as UserRole,
      full_name: decoded.full_name
    };

    next();
  } catch (err) {
    sendError(res, 'เซสชันหมดอายุหรือไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่', 403, err);
  }
};

export const requireRole = (...roles: UserRole[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user || !roles.includes(req.user.role)) {
      sendError(res, 'คุณไม่มีสิทธิ์เข้าถึงฟังก์ชันนี้', 403);
      return;
    }
    next();
  };
};

