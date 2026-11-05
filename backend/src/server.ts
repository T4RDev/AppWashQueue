import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';

// Import Routes
import authRoutes from './routes/authRoutes';
import vehicleRoutes from './routes/vehicleRoutes';
import shopRoutes from './routes/shopRoutes';
import ownerRoutes from './routes/ownerRoutes';
import bookingRoutes from './routes/bookingRoutes';
import walletRoutes from './routes/walletRoutes';
import reviewRoutes from './routes/reviewRoutes';
import adminRoutes from './routes/adminRoutes';
import notificationRoutes from './routes/notificationRoutes';

// Database & Scheduler
import { testDatabaseConnection } from './config/database';
import { initReminderScheduler } from './utils/scheduler';
import { sendError } from './utils/response';

dotenv.config();

const app = express();
const PORT: number = Number(process.env.PORT) || 5000;

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static file serving for uploads (Shops, ID Cards, Slips)
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// Health Check Endpoint
app.get('/api/health', (req: Request, res: Response) => {
  res.json({
    status: 'OK',
    message: 'WashQ TypeScript RESTful API Server is running smoothly',
    timestamp: new Date().toISOString()
  });
});

// Mount API Routes
app.use('/api/auth', authRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/owner', ownerRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);

// Global 404 Route Handler
app.use((req: Request, res: Response) => {
  sendError(res, `ไม่พบ Endpoint: ${req.method} ${req.originalUrl}`, 404);
});

// Global Error Handler Middleware
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('[Global Error Handler]:', err);
  sendError(res, err.message || 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์', 500, err);
});

// Start Server
app.listen(PORT, async () => {
  console.log(`====================================================`);
  console.log(`[WashQ Backend] Server is running on port ${PORT}`);
  console.log(`[WashQ Backend] Mode: ${process.env.NODE_ENV || 'development'}`);
  console.log(`====================================================`);

  // ทดสอบการเชื่อมต่อฐานข้อมูล
  await testDatabaseConnection();

  // เริ่มการทำงานของ Background Scheduler แจ้งเตือนล่วงหน้า 30 นาที
  initReminderScheduler();
});

export default app;
