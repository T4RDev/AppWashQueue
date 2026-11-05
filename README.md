# WashQ - Car Wash Queue Booking Application
(แอปพลิเคชันจองคิวล้างรถ)

## โครงสร้างโปรเจกต์ (Project Structure)

```
App_WashQueue/
├── backend/                  # Node.js + Express + TypeScript RESTful API Server
│   ├── src/
│   │   ├── config/           # Database & Third-party configurations
│   │   ├── controllers/      # Route controllers (Business logic)
│   │   ├── middlewares/      # Auth (JWT), Upload (Multer), Validators
│   │   ├── routes/           # Express API endpoints
│   │   ├── utils/            # Helper functions, FCM notifications
│   │   └── server.ts         # Entry point for backend server (TypeScript)
│   ├── uploads/              # Stored image files (Shops, ID cards, Slips)
│   ├── tsconfig.json         # TypeScript configuration
│   ├── .env.example          # Environment variables template
│   └── package.json          # Node dependencies & TypeScript scripts
│
├── frontend/                 # Flutter Mobile Application (Android / iOS)
│   ├── lib/
│   │   ├── core/             # API clients, Constants, Theme, Routes
│   │   ├── models/           # Data models
│   │   ├── providers/        # State management (Provider)
│   │   ├── screens/          # App UI screens (Guest, Member, Owner, Admin)
│   │   ├── widgets/          # Reusable UI components
│   │   └── main.dart         # Entry point for Flutter app
│   └── pubspec.yaml          # Flutter dependencies
│
└── WashQ-screens/            # UI Mockup & Design References (21 screens)
```

## เครื่องมือที่ติดตั้งเรียบร้อยแล้ว (Installed Tools)

### Backend (Node.js & Express)
- `express`: Framework สำหรับสร้าง RESTful API
- `mysql2`: ไลบรารีเชื่อมต่อฐานข้อมูล MySQL รองรับ Connection Pool และ Promise
- `cors`: รองรับ Cross-Origin Resource Sharing
- `dotenv`: จัดการ Environment Variables (.env)
- `jsonwebtoken`: ระบบ Authentication ด้วย Access Token (JWT)
- `bcryptjs`: เข้ารหัสผ่าน Password และข้อมูล Sensitive (PDPA)
- `multer`: ระบบรับอัปโหลดไฟล์รูปภาพ
- `node-cron`: ตั้งเวลา Background Task (เช่น ยิงแจ้งเตือนล่วงหน้า 30 นาที)
- `promptpay-qr` & `qrcode`: สร้าง QR Code พร้อมเพย์สำหรับเติมเงิน Wallet
- `nodemon`: เครื่องมือ Auto-reload ระหว่างการพัฒนา

### Frontend (Flutter & Dart)
- `http`: ติดต่อเชื่อมโยงกับ REST API
- `provider`: จัดการ State Management
- `shared_preferences`: บันทึก Token และ Local User Session
- `google_maps_flutter` & `geolocator`: แผนที่ค้นหาร้านและพิกัด GPS ปัจจุบัน
- `image_picker`: จัดการเลือกรูปภาพจากกล้องหรือคลังภาพ
- `intl`: จัดการฟอร์แมตวันเวลา และสกุลเงินบาท

---

## วิธีทดสอบรันเบื้องต้น

### 1. รัน Backend
```bash
cd backend
npm run dev
```
เซิร์ฟเวอร์จะเปิดที่ `http://localhost:5000` (ทดสอบ Health Check ได้ที่ `http://localhost:5000/api/health`)

### 2. รัน Frontend
```bash
cd frontend
flutter run
```

