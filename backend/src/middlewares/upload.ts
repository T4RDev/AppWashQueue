import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Helper สร้างโฟลเดอร์ถ้ายังไม่มี
const ensureDirectoryExistence = (dirPath: string) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadPath = 'uploads/';
    if (file.fieldname === 'id_card') {
      uploadPath += 'id_cards/';
    } else if (file.fieldname === 'shop_images') {
      uploadPath += 'shops/';
    } else if (file.fieldname === 'slip') {
      uploadPath += 'slips/';
    }
    ensureDirectoryExistence(uploadPath);
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  }
});

const fileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedExts = /jpeg|jpg|png|webp|pdf/i;
  const ext = path.extname(file.originalname).toLowerCase().replace('.', '');

  const extValid = allowedExts.test(ext);
  const mimeValid = /image\/(jpeg|jpg|png|webp)|application\/pdf|application\/octet-stream/i.test(file.mimetype);

  if (extValid || mimeValid) {
    cb(null, true);
  } else {
    cb(new Error('รองรับเฉพาะไฟล์รูปภาพ (jpg, jpeg, png, webp) หรือเอกสาร PDF เท่านั้น'));
  }
};

export const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter
});

