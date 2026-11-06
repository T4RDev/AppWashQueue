import pool from './database';
import { hashPassword } from '../utils/password';

async function seedSampleData() {
  const connection = await pool.getConnection();
  try {
    console.log('[Seed] Seeding sample shop data...');

    // 1. สร้าง User Owner
    const pw = await hashPassword('password123');
    await connection.execute(`
      INSERT INTO users (email, password_hash, full_name, phone, role, status)
      VALUES ('owner@washq.com', '${pw}', 'สมชาย คาร์แคร์', '0812345678', 'owner', 'active')
      ON DUPLICATE KEY UPDATE id=id;
    `);

    const [userRows]: any = await connection.execute("SELECT id FROM users WHERE email = 'owner@washq.com'");
    const ownerId = userRows[0].id;

    // กระเป๋าเงิน
    await connection.execute(`
      INSERT INTO wallets (user_id, balance, pending_balance)
      VALUES (${ownerId}, 0.00, 0.00)
      ON DUPLICATE KEY UPDATE id=id;
    `);

    // 2. สร้าง Shop
    await connection.execute(`
      INSERT INTO shops (
        owner_id, shop_name, phone, description, address,
        latitude, longitude, open_time, close_time,
        accepts_motorcycle, accepts_car, accepts_suv,
        id_card_image_url, bank_name, bank_account_name, bank_account_number, status
      ) VALUES (
        ${ownerId}, 'Clean & Shine Car Care สาขาใหญ่', '0812345678',
        'ศูนย์บริการล้างรถและเคลือบแก้วครบวงจร สะอาด รวดเร็ว ด้วยน้ำยามาตรฐานสากล',
        '123 ถนนสุขุมวิท แขวงคลองเตย เขตคลองเตย กรุงเทพมหานคร 10110',
        13.736717, 100.560787, '08:00:00', '19:00:00',
        1, 1, 1, 'uploads/id_cards/sample.png', 'กสิกรไทย', 'สมชาย คาร์แคร์', '123-4-56789-0', 'approved'
      ) ON DUPLICATE KEY UPDATE id=id;
    `);

    const [shopRows]: any = await connection.execute(`SELECT id FROM shops WHERE owner_id = ${ownerId}`);
    const shopId = shopRows[0].id;

    // 3. วันเปิดทำการ (จันทร์ - เสาร์)
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    for (const d of days) {
      await connection.execute(`
        INSERT INTO shop_operating_days (shop_id, day_of_week, is_active)
        VALUES (${shopId}, '${d}', 1)
        ON DUPLICATE KEY UPDATE is_active=1;
      `);
    }

    // 4. สล็อตเวลา
    const slots = [
      ['09:00:00', '10:30:00', 3],
      ['10:30:00', '12:00:00', 3],
      ['13:00:00', '14:30:00', 3],
      ['14:30:00', '16:00:00', 3],
      ['16:00:00', '17:30:00', 2],
    ];
    for (const [st, et, cap] of slots) {
      await connection.execute(`
        INSERT INTO shop_time_slots (shop_id, start_time, end_time, capacity, vehicle_type, is_active)
        VALUES (${shopId}, '${st}', '${et}', ${cap}, 'all', 1)
      `);
    }

    // 5. บริการและราคา
    const services = [
      ['ล้างอัดฉีด', 'car', 150.00],
      ['ดูดฝุ่นภายใน', 'car', 80.00],
      ['เคลือบสี', 'car', 350.00],
      ['ขัดเคลือบสีระเบิดขี้ไคล', 'car', 1200.00],
      ['ล้างสี ดูดฝุ่น SUV / กระบะ', 'suv', 350.00],
      ['เคลือบสี SUV', 'suv', 450.00],
      ['ล้างรถจักรยานยนต์', 'motorcycle', 100.00],
      ['ล้างรถจักรยานยนต์ บิ๊กไบค์', 'motorcycle', 180.00],
    ];
    for (const [name, vt, price] of services) {
      await connection.execute(`
        INSERT INTO services (shop_id, name, vehicle_type, price, is_active)
        VALUES (${shopId}, '${name}', '${vt}', ${price}, 1)
      `);
    }

    console.log('[Seed] Sample shop seeded successfully!');
  } catch (err) {
    console.error('[Seed Error]:', err);
  } finally {
    connection.release();
  }
}

seedSampleData().then(() => process.exit(0));

