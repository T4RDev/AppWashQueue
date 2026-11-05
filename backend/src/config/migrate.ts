import fs from 'fs';
import path from 'path';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

export const runMigrations = async () => {
  console.log('[Migration] Connecting with multipleStatements to execute schema...');

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'defaultdb',
    port: Number(process.env.DB_PORT),
    ssl: { rejectUnauthorized: false },
    multipleStatements: true,
  });

  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    let sqlContent = fs.readFileSync(schemaPath, 'utf8');

    // ลบ CREATE DATABASE และ USE washqueue_db ออกเพื่อให้ทำงานบน defaultdb
    sqlContent = sqlContent
      .replace(/CREATE DATABASE[^\n;]+;/gi, '')
      .replace(/USE[^\n;]+;/gi, '');

    await connection.query(sqlContent);
    console.log('[Migration] All tables and admin seed created successfully!');

    const [tables]: any = await connection.query('SHOW TABLES');
    console.log('[Migration] Created tables:', tables.map((t: any) => Object.values(t)[0]));
  } catch (error) {
    console.error('[Migration Error]:', error);
  } finally {
    await connection.end();
  }
};

if (require.main === module) {
  runMigrations().then(() => process.exit(0));
}
