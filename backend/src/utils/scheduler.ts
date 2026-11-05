import cron from 'node-cron';
import pool from '../config/database';
import { createNotification } from './notification';
import { RowDataPacket } from 'mysql2';

// 1.3.2 (11) แจ้งเตือนล่วงหน้า 30 นาทีก่อนถึงเวลาเข้าใช้บริการ
export const initReminderScheduler = () => {
  // รันตรวจสอบทุก 1 นาที
  cron.schedule('* * * * *', async () => {
    try {
      // ค้นหารายการจองที่:
      // 1. วันนี้ (booking_date = CURDATE())
      // 2. สถานะ pending_service
      // 3. เวลาเริ่มบริการอยู่ในช่วง 25 ถึง 35 นาทีข้างหน้า
      const [bookings] = await pool.execute<RowDataPacket[]>(`
        SELECT 
          b.id, b.user_id, b.booking_code, b.booking_date,
          ts.start_time, ts.end_time,
          s.shop_name, s.address,
          v.plate_number
        FROM bookings b
        JOIN shop_time_slots ts ON ts.id = b.time_slot_id
        JOIN shops s ON s.id = b.shop_id
        JOIN vehicles v ON v.id = b.vehicle_id
        WHERE b.status = 'pending_service'
          AND b.booking_date = CURDATE()
          AND TIMESTAMPDIFF(MINUTE, NOW(), CONCAT(b.booking_date, ' ', ts.start_time)) BETWEEN 25 AND 35
          AND NOT EXISTS (
            SELECT 1 FROM notifications n
            WHERE n.user_id = b.user_id 
              AND n.type = 'reminder_30m' 
              AND n.reference_id = b.id
          )
      `);

      for (const b of bookings) {
        await createNotification(
          b.user_id,
          'แจ้งเตือนคิวล้างรถในอีก 30 นาที ⏰',
          `คิวล้างรถทะเบียน ${b.plate_number} ของคุณที่ร้าน ${b.shop_name} กำลังจะถึงเวลาในรอบ ${b.start_time} - ${b.end_time} น. กรุณาเตรียมนำรถเข้ารับบริการครับ`,
          'reminder_30m',
          b.id
        );
        console.log(`[Scheduler] Sent 30-min reminder for booking ${b.booking_code} to user ${b.user_id}`);
      }
    } catch (error) {
      console.error('[Scheduler Error] Error checking booking reminders:', error);
    }
  });

  console.log('[WashQ Scheduler] 30-minute reminder job initialized successfully.');
};
