import { Response } from 'express';
import pool from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../types';
import { ResultSetHeader, RowDataPacket } from 'mysql2';

// ดึงรายการรถทั้งหมดของสมาชิก
export const getMyVehicles = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id, plate_number, vehicle_type, brand, model, created_at FROM vehicles WHERE user_id = ? ORDER BY id DESC',
      [userId]
    );
    sendSuccess(res, rows);
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการดึงข้อมูลรถ', 500, error);
  }
};

// เพิ่มข้อมูลรถคันใหม่
export const addVehicle = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { plate_number, vehicle_type, brand, model } = req.body;

    if (!plate_number || !vehicle_type) {
      sendError(res, 'กรุณาระบุ ป้ายทะเบียน และ ประเภทรถ', 400);
      return;
    }

    if (!['motorcycle', 'car', 'suv'].includes(vehicle_type)) {
      sendError(res, 'ประเภทรถต้องเป็น motorcycle, car หรือ suv เท่านั้น', 400);
      return;
    }

    // ตรวจสอบป้ายทะเบียนซ้ำในบัญชีของผู้ใช้
    const [existing] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM vehicles WHERE user_id = ? AND plate_number = ?',
      [userId, plate_number]
    );

    if (existing.length > 0) {
      sendError(res, 'คุณได้เพิ่มป้ายทะเบียนนี้ในระบบแล้ว', 400);
      return;
    }

    const [result] = await pool.execute<ResultSetHeader>(
      `INSERT INTO vehicles (user_id, plate_number, vehicle_type, brand, model)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, plate_number, vehicle_type, brand || '-', model || '-']
    );

    sendSuccess(
      res,
      {
        id: result.insertId,
        user_id: userId,
        plate_number,
        vehicle_type,
        brand: brand || '-',
        model: model || '-'
      },
      'เพิ่มข้อมูลรถเรียบร้อยแล้ว',
      201
    );
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการเพิ่มรถ', 500, error);
  }
};

// แก้ไขข้อมูลรถ
export const updateVehicle = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const vehicleId = req.params.id;
    const { plate_number, vehicle_type, brand, model } = req.body;

    // ตรวจสอบว่าเป็นรถของ User คนนี้จริงหรือไม่
    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM vehicles WHERE id = ? AND user_id = ?',
      [vehicleId, userId]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบข้อมูลรถหรือคุณไม่มีสิทธิ์แก้ไข', 404);
      return;
    }

    // ตรวจสอบทะเบียนซ้ำกรณีเปลี่ยนเลขทะเบียน
    if (plate_number) {
      const [duplicate] = await pool.execute<RowDataPacket[]>(
        'SELECT id FROM vehicles WHERE user_id = ? AND plate_number = ? AND id != ?',
        [userId, plate_number, vehicleId]
      );
      if (duplicate.length > 0) {
        sendError(res, 'ป้ายทะเบียนนี้มีอยู่ในบัญชีของคุณแล้ว', 400);
        return;
      }
    }

    await pool.execute(
      `UPDATE vehicles
       SET plate_number = COALESCE(?, plate_number),
           vehicle_type = COALESCE(?, vehicle_type),
           brand = COALESCE(?, brand),
           model = COALESCE(?, model)
       WHERE id = ? AND user_id = ?`,
      [plate_number, vehicle_type, brand, model, vehicleId, userId]
    );

    sendSuccess(res, null, 'อัปเดตข้อมูลรถเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการแก้ไขข้อมูลรถ', 500, error);
  }
};

// ลบข้อมูลรถ
export const deleteVehicle = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const vehicleId = req.params.id;

    const [rows] = await pool.execute<RowDataPacket[]>(
      'SELECT id FROM vehicles WHERE id = ? AND user_id = ?',
      [vehicleId, userId]
    );

    if (rows.length === 0) {
      sendError(res, 'ไม่พบข้อมูลรถหรือคุณไม่มีสิทธิ์ลบ', 404);
      return;
    }

    // ตรวจสอบว่ารถคันนี้มีการจองที่ยังไม่เสร็จสิ้นหรือไม่
    const [activeBookings] = await pool.execute<RowDataPacket[]>(
      `SELECT id FROM bookings
       WHERE vehicle_id = ? AND status IN ('pending_service', 'checked_in', 'in_service')`,
      [vehicleId]
    );

    if (activeBookings.length > 0) {
      sendError(res, 'ไม่สามารถลบรถคันนี้ได้เนื่องจากมีรายการจองคิวที่ยังไม่เสร็จสิ้น', 400);
      return;
    }

    await pool.execute('DELETE FROM vehicles WHERE id = ? AND user_id = ?', [vehicleId, userId]);
    sendSuccess(res, null, 'ลบข้อมูลรถเรียบร้อยแล้ว');
  } catch (error) {
    sendError(res, 'เกิดข้อผิดพลาดในการลบข้อมูลรถ', 500, error);
  }
};

