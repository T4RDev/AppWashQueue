import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../types';
import { RowDataPacket } from 'mysql2';

// ดึงรายการแจ้งเตือนของฉัน
export const getMyNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const [rows] = await pool.execute<RowDataPacket[]>(
      `SELECT id, title, message, type, reference_id, is_read, created_at
       FROM notifications
       WHERE user_id = ?
       ORDER BY created_at DESC LIMIT 50`,
      [userId]
    );

    const [unreadCount] = await pool.execute<RowDataPacket[]>(
      'SELECT COUNT(id) AS unread_count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    sendSuccess(res, {
      notifications: rows,
      unread_count: unreadCount[0].unread_count
    });
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงการแจ้งเตือน', 500, error);
  }
};

// ทำเครื่องหมายว่าอ่านแล้ว
export const markAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const notificationId = req.params.id;

    await pool.execute(
      'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
      [notificationId, userId]
    );

    sendSuccess(res, null, 'ทำเครื่องหมายว่าอ่านแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

// อ่านทั้งหมด
export const markAllAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;

    await pool.execute('UPDATE notifications SET is_read = TRUE WHERE user_id = ?', [userId]);

    sendSuccess(res, null, 'ทำเครื่องหมายอ่านทั้งหมดเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาด', 500, error);
  }
};

