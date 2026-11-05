import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

// ตรวจสอบการใช้งาน SSL (เช่น Aiven Cloud MySQL)
const useSSL = process.env.DB_SSL === 'true' || (process.env.DB_HOST && process.env.DB_HOST.includes('aivencloud.com'));

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'defaultdb',
  port: Number(process.env.DB_PORT) || 3306,
  ssl: useSSL ? { rejectUnauthorized: false } : undefined,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true
});

// ฟังก์ชันสำหรับทดสอบการเชื่อมต่อ Database
export const testDatabaseConnection = async (): Promise<boolean> => {
  try {
    const connection = await pool.getConnection();
    console.log('[WashQ Database] Connected to MySQL database successfully.');
    connection.release();
    return true;
  } catch (error) {
    console.error('[WashQ Database] MySQL connection failed:', error);
    return false;
  }
};

export default pool;
