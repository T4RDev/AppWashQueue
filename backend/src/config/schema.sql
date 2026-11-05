-- ====================================================================
-- WashQ Database Schema (MySQL)
-- ออกแบบตรงตามข้อกำหนดขอบเขตโครงงาน 100%
-- ====================================================================

CREATE DATABASE IF NOT EXISTS washqueue_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE washqueue_db;

-- --------------------------------------------------------------------
-- 1. ตารางผู้ใช้งาน (Users)
-- รองรับ: สมาชิก (member), เจ้าของร้าน (owner), ผู้ดูแลระบบ (admin)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(191) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,                -- NULL ได้กรณีเข้าสู่ระบบผ่าน Google ครั้งแรก
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    role ENUM('member', 'owner', 'admin') NOT NULL DEFAULT 'member',
    status ENUM('active', 'suspended') NOT NULL DEFAULT 'active',
    google_id VARCHAR(100) NULL UNIQUE,
    fcm_token VARCHAR(255) NULL,                    -- Token สำหรับ Push Notification (FCM)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 2. ตารางรีเซ็ตรหัสผ่าน (Password Resets)
-- รองรับ: ข้อ 1.3.2 (3) กู้คืนรหัสผ่านส่งรหัส OTP ไปยังอีเมล
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(191) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_otp (email, otp_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 3. ตารางข้อมูลรถส่วนตัวของสมาชิก (Vehicles)
-- รองรับ: ข้อ 1.3.1 (1), 1.3.2 (2, 4) สมาชิก 1 คนมีได้หลายคัน
-- ป้ายทะเบียนไม่ซ้ำกันในแต่ละผู้ใช้งาน
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plate_number VARCHAR(50) NOT NULL,
    vehicle_type ENUM('motorcycle', 'car', 'suv') NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_plate (user_id, plate_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 4. ตารางข้อมูลร้านล้างรถ (Shops)
-- รองรับ: ข้อ 1.3.1 (4), 1.3.3 (2), 1.3.4 (2, 3)
-- มีข้อมูลร้าน, ข้อมูลพิกัด, รูปบัตรปชช. (PDPA), บัญชีธนาคารรับเงิน
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shops (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    shop_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    description TEXT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    accepts_motorcycle BOOLEAN NOT NULL DEFAULT TRUE,
    accepts_car BOOLEAN NOT NULL DEFAULT TRUE,
    accepts_suv BOOLEAN NOT NULL DEFAULT TRUE,
    id_card_image_url VARCHAR(255) NOT NULL,        -- เก็บแบบเข้ารหัสตามมาตรฐาน PDPA
    bank_name VARCHAR(100) NOT NULL,
    bank_account_name VARCHAR(150) NOT NULL,
    bank_account_number VARCHAR(50) NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'suspended') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 5. ตารางรูปถ่ายหน้าร้าน (Shop Images)
-- รองรับ: ข้อ 1.3.1 (4) รูปถ่ายหน้าร้านขั้นต่ำ 3 รูป
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shop_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shop_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    is_cover BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 6. ตารางวันให้บริการของร้าน (Shop Operating Days)
-- รองรับ: ข้อ 1.3.1 (2), 1.3.3 (3) เช่น จันทร์, อังคาร, พุธ
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shop_operating_days (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shop_id INT NOT NULL,
    day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
    UNIQUE KEY uk_shop_day (shop_id, day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 7. ตารางสล็อตเวลาให้บริการ (Shop Time Slots)
-- รองรับ: ข้อ 1.3.1 (2), 1.3.3 (4) ช่วงเวลา, จำนวนคิวที่รับ, ประเภทรถ
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shop_time_slots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shop_id INT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity INT NOT NULL DEFAULT 1,                -- จำนวนคิวที่รับได้ต่อสล็อต
    vehicle_type ENUM('all', 'motorcycle', 'car', 'suv') NOT NULL DEFAULT 'all',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,        -- เปิด/ปิด การใช้งานแทนการลบเมื่อเคยถูกใช้งานแล้ว
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 8. ตารางบริการและราคา (Services)
-- รองรับ: ข้อ 1.3.1 (2), 1.3.3 (5) ชื่อบริการ, ประเภทรถ, ราคา
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shop_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,                     -- เช่น ล้างอัดฉีด, ดูดฝุ่น, ขัดเคลือบสี
    vehicle_type ENUM('motorcycle', 'car', 'suv') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 9. ตารางโค้ดส่วนลดของระบบ (Discounts)
-- รองรับ: ข้อ 1.3.4 (5) Admin สร้าง/แก้ไข ส่วนลดเป็นเปอร์เซ็นต์ เปิด/ปิดได้
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS discounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_percent DECIMAL(5, 2) NOT NULL,        -- ส่วนลดเป็น % เช่น 10.00%
    is_active BOOLEAN NOT NULL DEFAULT TRUE,        -- เปิด/ปิด สถานะส่วนลด
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 10. ตารางกระเป๋าเงิน (Wallets)
-- รองรับ: ข้อ 1.3.2 (6, 7), 1.3.3 (10), 1.3.4 (4)
-- balance: เงินที่ใช้งานหรือถอนได้จริง
-- pending_balance: เงิน Escrow ของร้านค้า (รอปรับเป็นบริการเสร็จสิ้นก่อนปลดล็อก)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wallets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    pending_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 11. ตารางการจองคิวล้างรถ (Bookings)
-- รองรับ: ข้อ 1.3.2 (6, 8, 9), 1.3.3 (6, 7), 1.3.4 (7)
-- การตัดเงิน Wallet แบ่งเข้าร้าน 95% เข้าระบบ 5% หลังหักส่วนลด
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_code VARCHAR(30) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    shop_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    service_id INT NOT NULL,
    time_slot_id INT NOT NULL,
    discount_id INT NULL,
    booking_date DATE NOT NULL,
    
    -- การคำนวณราคาและส่วนแบ่ง
    original_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    final_price DECIMAL(10, 2) NOT NULL,
    shop_share_amount DECIMAL(10, 2) NOT NULL,       -- 95% ของยอดหลังหักส่วนลด
    system_fee_amount DECIMAL(10, 2) NOT NULL,       -- 5% ของยอดหลังหักส่วนลด
    
    -- สถานะตามที่ระบุในขอบเขต:
    -- เข้ารับบริการ, กำลังให้บริการ, บริการเสร็จสิ้น, ไม่มาตามนัด
    status ENUM(
        'pending_service',     -- รอเข้ารับบริการ
        'checked_in',           -- เข้ารับบริการ
        'in_service',           -- กำลังให้บริการ
        'completed',            -- บริการเสร็จสิ้น
        'no_show',              -- ไม่มาตามนัด
        'cancelled_by_user',    -- ยกเลิกโดยสมาชิก (ก่อน 24 ชม.)
        'cancelled_by_shop'     -- ยกเลิกโดยร้านค้า (ฉุกเฉิน)
    ) NOT NULL DEFAULT 'pending_service',
    
    payment_status ENUM('paid', 'refunded', 'released_to_shop') NOT NULL DEFAULT 'paid',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE RESTRICT,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
    FOREIGN KEY (time_slot_id) REFERENCES shop_time_slots(id) ON DELETE RESTRICT,
    FOREIGN KEY (discount_id) REFERENCES discounts(id) ON DELETE SET NULL,
    
    INDEX idx_booking_date_shop (shop_id, booking_date),
    INDEX idx_user_bookings (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 12. ตารางประวัติธุรกรรมกระเป๋าเงิน (Wallet Transactions)
-- รองรับ: ข้อ 1.3.2 (6, 7, 8) เติมเงิน, จ่ายค่าจอง, รับเงินคืน, ถอนเงิน
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    wallet_id INT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    type ENUM('topup', 'booking_payment', 'booking_earning', 'refund', 'withdrawal') NOT NULL,
    status ENUM('pending', 'completed', 'rejected') NOT NULL DEFAULT 'completed',
    reference_id VARCHAR(100) NULL,                 -- ผูกกับ booking_id หรือ withdrawal_request_id
    slip_url VARCHAR(255) NULL,                     -- รูปสลิปการโอนเงิน (กรณีเติมเงินผ่าน QR)
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
    INDEX idx_wallet_created (wallet_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 13. ตารางคำขอถอนเงิน (Withdrawal Requests)
-- รองรับ: ข้อ 1.3.3 (10), 1.3.4 (4, 8)
-- อนุมัติถอนเงินของสมาชิก และร้านค้า โอนเงินเข้าบัญชีธนาคาร
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    wallet_id INT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    bank_account_name VARCHAR(150) NOT NULL,
    bank_account_number VARCHAR(50) NOT NULL,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    transfer_proof_url VARCHAR(255) NULL,           -- สลิปหลักฐานการโอนจากแอดมิน
    admin_notes TEXT NULL,
    processed_by INT NULL,
    processed_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT,
    FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_withdrawals (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 14. ตารางรีวิวและให้คะแนน (Reviews)
-- รองรับ: ข้อ 1.3.2 (10) สมาชิกให้คะแนนร้านที่เสร็จแล้ว 1 - 5 คะแนน
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    user_id INT NOT NULL,
    shop_id INT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
    INDEX idx_shop_rating (shop_id, rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- 15. ตารางการแจ้งเตือน (Notifications)
-- รองรับ: ข้อ 1.3.2 (11, 12), 1.3.3 (8)
-- เตือนก่อน 30 นาที, เตือนเมื่อเสร็จ, เตือนร้านเมื่อมีจอง/ยกเลิก
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('booking_confirmed', 'reminder_30m', 'service_completed', 'booking_cancelled', 'wallet_update', 'system') NOT NULL,
    reference_id INT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_unread (user_id, is_read, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------------
-- ข้อมูลเริ่มต้นสำหรับ Admin (Default Seed Admin)
-- Password: password123 (bcrypt hashed)
-- --------------------------------------------------------------------
INSERT INTO users (email, password_hash, full_name, phone, role, status)
VALUES (
    'admin@washqueue.com',
    '$2a$10$wO0I7Z1m27qGgP9c2F5Mge8b5s2m8rY7jL1B6uM8h7o5N6k7P4wGi',
    'System Administrator',
    '0800000000',
    'admin',
    'active'
) ON DUPLICATE KEY UPDATE id=id;

