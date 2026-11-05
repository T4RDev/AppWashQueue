import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../types';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

// 1.3.2 (10) ให้คะแนนร้านที่เข้ารับบริการเสร็จแล้ว (1 - 5 คะแนน)
export const submitReview = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { booking_id, rating, comment } = req.body;

    if (!booking_id || !rating) {
      sendError(res, 'กรุณาระบุ booking_id และคะแนนรีวิว (rating)', 400);
      return;
    }

    const numRating = Number(rating);
    if (numRating < 1 || numRating > 5) {
      sendError(res, 'คะแนนรีวิวต้องอยู่ระหว่าง 1 ถึง 5 คะแนน', 400);
      return;
    }

    // ตรวจสอบว่าคิวนี้เป็นของ User คนนี้จริง และสถานะต้องเป็น 'completed'
    const [bookings] = await pool.execute<RowDataPacket[]>(
      'SELECT id, shop_id, status FROM bookings WHERE id = ? AND user_id = ?',
      [booking_id, userId]
    );

    if (bookings.length === 0) {
      sendError(res, 'ไม่พบรายการจองนี้หรือคุณไม่มีสิทธิ์รีวิว', 404);
      return;
    }

    const booking = bookings[0];
    if (booking.status !== 'completed') {
      sendError(res, 'สามารถรีวิวได้เฉพาะบริการที่เสร็จสิ้นแล้วเท่านั้น', 400);
      return;
    }

    // ตรวจสอบว่าเคยรีวิวรายการนี้ไปแล้วหรือยัง
    const [existing] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM reviews WHERE booking_id = ?',
      [booking_id]
    );

    if (existing.length > 0) {
      sendError(res, 'คุณได้ให้คะแนนรีวิวบริการนี้ไปแล้ว', 400);
      return;
    }

    const [result] = await pool.execute<ResultSetHeader>(
      `INSERT INTO reviews (booking_id, user_id, shop_id, rating, comment)
       VALUES (?, ?, ?, ?, ?)`,
      [booking_id, userId, booking.shop_id, numRating, comment || null]
    );

    sendSuccess(res, { review_id: result.insertId }, 'ส่งคะแนนรีวิวเรียบร้อยแล้ว ขอบคุณสำหรับความคิดเห็น!', 201);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการส่งรีวิว', 500, error);
  }
};

// ดึงรีวิวของร้าน
export const getShopReviews = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const shopId = req.params.shopId;
    const [rows] = await pool.execute<RowDataPacket[]>(
      `SELECT r.id, r.rating, r.comment, r.created_at,
              u.full_name AS reviewer_name
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       WHERE r.shop_id = ?
       ORDER BY r.created_at DESC`,
      [shopId]
    );
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลรีวิว', 500, error);
  }
};
