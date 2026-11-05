import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../core/app_theme.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _openTimeController = TextEditingController(text: '08:00');
  final _closeTimeController = TextEditingController(text: '18:00');

  final _bankNameController = TextEditingController();
  final _bankAccNameController = TextEditingController();
  final _bankAccNumController = TextEditingController();

  XFile? _idCardFile;
  final List<XFile> _shopImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _bankNameController.dispose();
    _bankAccNameController.dispose();
    _bankAccNumController.dispose();
    super.dispose();
  }

  Future<void> _pickIdCard() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _idCardFile = picked);
  }

  Future<void> _pickShopImages() async {
    final pickedList = await _picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() => _shopImages.addAll(pickedList));
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idCardFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดสำเนาบัตรประชาชนเพื่อยืนยันตัวตน (PDPA)'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_shopImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดรูปถ่ายหน้าร้านอย่างน้อย 3 รูป'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<http.MultipartFile> files = [];

      // Add ID card (รองรับทั้ง Web และ Mobile)
      final idBytes = await _idCardFile!.readAsBytes();
      files.add(http.MultipartFile.fromBytes('id_card', idBytes, filename: _idCardFile!.name));

      // Add shop images
      for (final img in _shopImages) {
        final imgBytes = await img.readAsBytes();
        files.add(http.MultipartFile.fromBytes('shop_images', imgBytes, filename: img.name));
      }

      final fields = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'shop_name': _shopNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descController.text.trim(),
        'latitude': '13.7563', // ตัวอย่างพิกัด กทม.
        'longitude': '100.5018',
        'open_time': '${_openTimeController.text.trim()}:00',
        'close_time': '${_closeTimeController.text.trim()}:00',
        'accepts_motorcycle': 'true',
        'accepts_car': 'true',
        'accepts_suv': 'true',
        'bank_name': _bankNameController.text.trim(),
        'bank_account_name': _bankAccNameController.text.trim(),
        'bank_account_number': _bankAccNumController.text.trim(),
      };

      final response = await ApiService().multipartPost(
        ApiConstants.shopRegister,
        fields: fields,
        files: files,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response.success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('ส่งคำขอสำเร็จ! 🎊'),
            content: const Text(
              'คำขอเปิดร้านของคุณถูกส่งไปยังผู้ดูแลระบบเรียบร้อยแล้ว เมื่อผ่านการตรวจสอบคุณจะสามารถเข้าสู่ระบบเพื่อจัดการร้านได้ทันที',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('กลับสู่หน้าหลัก'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครเป็นร้านล้างรถ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ข้อมูลบัญชีร้านค้า 🏪',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'ชื่อร้านคาร์แคร์'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'อีเมลสำหรับเข้าสู่ระบบของร้าน'),
                validator: (v) => v == null || !v.contains('@') ? 'กรุณากรอกอีเมลที่ถูกต้อง' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'รหัสผ่านร้านค้า'),
                validator: (v) => v == null || v.length < 6 ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'เบอร์ติดต่อร้าน'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกเบอร์ติดต่อ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ที่อยู่ร้านค้า'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกที่อยู่' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openTimeController,
                      decoration: const InputDecoration(labelText: 'เวลาเปิด (เช่น 08:00)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _closeTimeController,
                      decoration: const InputDecoration(labelText: 'เวลาปิด (เช่น 18:00)'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // เอกสารและภาพถ่าย
              const Text(
                'เอกสารและรูปภาพ 📷',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge, color: AppTheme.primaryColor),
                title: const Text('สำเนาบัตรประชาชน (เข้ารหัสตาม PDPA)'),
                subtitle: Text(_idCardFile != null ? 'เลือกแล้ว: ${_idCardFile!.name}' : 'ยังไม่ได้เลือกไฟล์'),
                trailing: ElevatedButton(onPressed: _pickIdCard, child: const Text('เลือกไฟล์')),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library, color: AppTheme.accentColor),
                title: const Text('รูปถ่ายหน้าร้าน (ขั้นต่ำ 3 รูป)'),
                subtitle: Text('เลือกแล้ว ${_shopImages.length} รูป'),
                trailing: ElevatedButton(onPressed: _pickShopImages, child: const Text('เพิ่มรูป')),
              ),
              const Divider(height: 32),

              // ข้อมูลธนาคารสำหรับรับเงิน
              const Text(
                'ข้อมูลบัญชีธนาคารสำหรับรับเงิน 🏦',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'ชื่อธนาคาร'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อธนาคาร' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccNameController,
                decoration: const InputDecoration(labelText: 'ชื่อบัญชี'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อบัญชี' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccNumController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'เลขที่บัญชี'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกเลขที่บัญชี' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ส่งคำขอเปิดร้านล้างรถ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

