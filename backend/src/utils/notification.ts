import pool from '../config/database';
import { NotificationType } from '../types';

export const createNotification = async (
  userId: number,
  title: string,
  message: string,
  type: NotificationType,
  referenceId: number | null = null
): Promise<void> => {
  try {
    await pool.execute(
      `INSERT INTO notifications (user_id, title, message, type, reference_id)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, title, message, type, referenceId]
    );
  } catch (error) {
    console.error(`[Notification Error] Failed to create notification for user ${userId}:`, error);
  }
};
