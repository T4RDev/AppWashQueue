import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import '../providers/auth_provider.dart';
import '../widgets/real_map_picker.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  int _currentStep = 1; // 1: ข้อมูลร้าน, 2: ที่ตั้ง & เวลา, 3: บัญชี & เอกสาร, 4: ส่งคำขอสำเร็จ

  // Step 1: ข้อมูลร้าน
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  bool _acceptsCar = true;
  bool _acceptsMotorcycle = true;
  bool _acceptsSuv = true;

  // Step 2: ที่ตั้ง & เวลา (อิงจาก Maps)
  final _addressController = TextEditingController(
    text: '123/45 ถนนมิตรภาพ ตำบลในเมือง อำเภอเมือง ขอนแก่น 40000',
  );
  double _latitude = 16.4322;
  double _longitude = 102.8236;
  bool _isLocating = false;
  final _openTimeController = TextEditingController(text: '08:00');
  final _closeTimeController = TextEditingController(text: '18:00');
  final List<String> _operatingDays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  final Set<String> _selectedDays = {
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  };

  // Step 3: บัญชี & เอกสาร
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedBank = 'กสิกรไทย';
  final _bankAccNumController = TextEditingController();
  final _bankAccNameController = TextEditingController();

  XFile? _idCardFile;
  final List<XFile> _shopImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _banks = [
    'กสิกรไทย',
    'ไทยพาณิชย์',
    'กรุงเทพ',
    'กรุงไทย',
    'กรุงศรีอยุธยา',
    'ทหารไทยธนชาต (ttb)',
    'ออมสิน',
    'พร้อมเพย์ (PromptPay)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user != null) {
        if (_emailController.text.isEmpty && user.email.isNotEmpty) {
          _emailController.text = user.email;
        }
        if (_phoneController.text.isEmpty && user.phone.isNotEmpty) {
          _phoneController.text = user.phone;
        }
        if (_bankAccNameController.text.isEmpty && user.fullName.isNotEmpty) {
          _bankAccNameController.text = user.fullName;
        }
      }
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bankAccNumController.dispose();
    _bankAccNameController.dispose();
    super.dispose();
  }

  // ดึงตำแหน่งพิกัดปัจจุบันจาก GPS
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted)
            AppSnackBar.showError(context, 'กรุณาอนุญาตการเข้าถึงพิกัด GPS');
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          AppSnackBar.showError(
            context,
            'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธถาวร กรุณาเปิดในตั้งค่า',
          );
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = double.parse(position.latitude.toStringAsFixed(6));
        _longitude = double.parse(position.longitude.toStringAsFixed(6));
        _isLocating = false;
      });

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'ดึงพิกัดจาก GPS สำเร็จ: $_latitude, $_longitude',
        );
      }
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        AppSnackBar.showError(
          context,
          'ไม่สามารถดึงพิกัด GPS ได้ ใช้พิกัดจำลองอัตโนมัติ',
        );
      }
    }
  }

  void _selectTime(TextEditingController controller) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0066FF)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() => controller.text = '$hour:$minute');
    }
  }

  Future<void> _pickIdCard() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _idCardFile = picked);
      if (mounted)
        AppSnackBar.showSuccess(
          context,
          'อัปโหลดสำเนาบัตรประชาชนเรียบร้อยแล้ว',
        );
    }
  }

  Future<void> _pickShopImages() async {
    final pickedList = await _picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() => _shopImages.addAll(pickedList));
    }
  }

  void _goToStep2() {
    if (_shopNameController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'กรุณากรอกชื่อร้านคาร์แคร์');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'กรุณากรอกเบอร์ติดต่อร้าน');
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _goToStep3() {
    if (_addressController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'กรุณากรอกที่อยู่ร้านค้า');
      return;
    }
    setState(() => _currentStep = 3);
  }

  MediaType _getMediaType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      AppSnackBar.showError(context, 'กรุณากรอกอีเมลร้านค้าให้ถูกต้อง');
      return;
    }
    if (_passwordController.text.length < 6) {
      AppSnackBar.showError(
        context,
        'รหัสผ่านร้านค้าต้องมีอย่างน้อย 6 ตัวอักษร',
      );
      return;
    }
    if (_bankAccNumController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'กรุณากรอกเลขที่บัญชีธนาคาร');
      return;
    }
    if (_bankAccNameController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'กรุณากรอกชื่อบัญชีธนาคาร');
      return;
    }
    if (_idCardFile == null) {
      AppSnackBar.showError(
        context,
        'กรุณาอัปโหลดสำเนาบัตรประชาชนเพื่อยืนยันตัวตน (PDPA)',
      );
      return;
    }
    if (_shopImages.length < 3) {
      AppSnackBar.showError(
        context,
        'กรุณาอัปโหลดรูปถ่ายหน้าร้านอย่างน้อย 3 รูป',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<http.MultipartFile> files = [];

      final idBytes = await _idCardFile!.readAsBytes();
      final idExt = _idCardFile!.name.contains('.')
          ? _idCardFile!.name.split('.').last.toLowerCase()
          : 'png';
      files.add(
        http.MultipartFile.fromBytes(
          'id_card',
          idBytes,
          filename: 'id_card_${DateTime.now().millisecondsSinceEpoch}.$idExt',
          contentType: _getMediaType(idExt),
        ),
      );

      for (int i = 0; i < _shopImages.length; i++) {
        final img = _shopImages[i];
        final imgBytes = await img.readAsBytes();
        final imgExt = img.name.contains('.')
            ? img.name.split('.').last.toLowerCase()
            : 'jpg';
        files.add(
          http.MultipartFile.fromBytes(
            'shop_images',
            imgBytes,
            filename:
                'shop_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$imgExt',
            contentType: _getMediaType(imgExt),
          ),
        );
      }

      final fields = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'shop_name': _shopNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? 'ศูนย์บริการล้างรถและคาร์แคร์ครบวงจร'
            : _descController.text.trim(),
        'latitude': _latitude.toString(),
        'longitude': _longitude.toString(),
        'open_time': '${_openTimeController.text.trim()}:00',
        'close_time': '${_closeTimeController.text.trim()}:00',
        'accepts_motorcycle': _acceptsMotorcycle ? 'true' : 'false',
        'accepts_car': _acceptsCar ? 'true' : 'false',
        'accepts_suv': _acceptsSuv ? 'true' : 'false',
        'bank_name': _selectedBank,
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
        setState(() => _currentStep = 4);
      } else {
        AppSnackBar.showError(context, response.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.showError(context, 'เกิดข้อผิดพลาดในการส่งคำขอ: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0xFF0F2B5C),
              ),
              onPressed: () {
                if (_currentStep > 1 && _currentStep < 4) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        title: const Text(
          'ขอเปิดร้านล้างรถ',
          style: TextStyle(
            color: Color(0xFF0F2B5C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stepper Header (Matches 1.5_Request_Open_Shop.png)
                  if (_currentStep < 4) _buildStepperHeader(),

                  const SizedBox(height: 20),

                  // Step Content
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                  if (_currentStep == 4) _buildStep4Success(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Horizontal Stepper Header
  Widget _buildStepperHeader() {
    final steps = [
      {'num': 1, 'title': 'ข้อมูลร้าน'},
      {'num': 2, 'title': 'ที่ตั้ง & เวลา'},
      {'num': 3, 'title': 'บัญชี & เอกสาร'},
      {'num': 4, 'title': 'ส่งคำขอ'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final stepNum = steps[index]['num'] as int;
          final title = steps[index]['title'] as String;
          final isCompleted = _currentStep > stepNum;
          final isCurrent = _currentStep == stepNum;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? const Color(0xFF0066FF)
                              : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0066FF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF0066FF)
                              : isCompleted
                              ? const Color(0xFF0F2B5C)
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 18,
                    height: 2,
                    color: _currentStep > stepNum
                        ? const Color(0xFF0066FF)
                        : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Step 1: ข้อมูลทั่วไปของร้านค้า
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลร้านคาร์แคร์ 🏪',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'กรอกรายละเอียดพื้นฐานของร้านเพื่อเริ่มต้นสร้างโปรไฟล์ร้านค้า',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 18),

        _buildInputField(
          controller: _shopNameController,
          label: 'ชื่อร้านคาร์แคร์ *',
          hint: 'เช่น Clean & Shine Car Care สาขาใหญ่',
          icon: Icons.storefront,
        ),
        const SizedBox(height: 14),

        _buildInputField(
          controller: _phoneController,
          label: 'เบอร์ติดต่อร้าน *',
          hint: 'เช่น 081-234-5678',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        _buildInputField(
          controller: _descController,
          label: 'รายละเอียดร้าน / บริการเด่น',
          hint: 'เช่น บริการล้างสี ดูดฝุ่น ขัดเคลือบสี เคลือบแก้ว ห้องรับรองติดแอร์',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 20),

        // ประเภทยานพาหนะที่รับ
        const Text(
          'ประเภทยานพาหนะที่ให้บริการ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildVehicleChip(
              '🚗 รถยนต์',
              _acceptsCar,
              () => setState(() => _acceptsCar = !_acceptsCar),
            ),
            const SizedBox(width: 8),
            _buildVehicleChip(
              '🏍️ มอเตอร์ไซค์',
              _acceptsMotorcycle,
              () => setState(() => _acceptsMotorcycle = !_acceptsMotorcycle),
            ),
            const SizedBox(width: 8),
            _buildVehicleChip(
              '🚙 รถ SUV',
              _acceptsSuv,
              () => setState(() => _acceptsSuv = !_acceptsSuv),
            ),
          ],
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _goToStep2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'ถัดไป (ตั้งค่าพิกัด & เวลา)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: ที่ตั้งและเวลาให้บริการ (อิงจาก Maps)
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ที่ตั้งร้านค้า (อิงจาก Maps) 📍',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'พิมพ์ค้นหาสถานที่จริง หรือลากหมุดบนแผนที่เพื่อระบุตำแหน่งร้านของคุณ',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Real Interactive Map Picker with Nominatim Search
        RealMapPicker(
          initialLat: _latitude,
          initialLng: _longitude,
          height: 270,
          onLocationChanged: (lat, lng, address) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
              if (address.isNotEmpty) {
                _addressController.text = address;
              }
            });
          },
        ),

        const SizedBox(height: 12),

        // Quick City Preset Chips
        Row(
          children: [
            const Text(
              'เลือกย่านด่วน: ',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCityChip(
                      'ขอนแก่น (ในเมือง)',
                      16.4322,
                      102.8236,
                      'ถนนศรีจันทร์ ตำบลในเมือง อำเภอเมือง ขอนแก่น 40000',
                    ),
                    const SizedBox(width: 6),
                    _buildCityChip(
                      'กรุงเทพ (สุขุมวิท)',
                      13.7367,
                      100.5608,
                      'ถนนสุขุมวิท แขวงคลองเตยเหนือ เขตวัฒนา กรุงเทพฯ 10110',
                    ),
                    const SizedBox(width: 6),
                    _buildCityChip(
                      'กรุงเทพ (สยาม)',
                      13.7462,
                      100.5347,
                      'ถนนพระราม 1 แขวงปทุมวัน เขตปทุมวัน กรุงเทพฯ 10330',
                    ),
                    const SizedBox(width: 6),
                    _buildCityChip(
                      'เชียงใหม่ (นิมมาน)',
                      18.7961,
                      98.9680,
                      'ถนนนิมมานเหมินท์ ตำบลสุเทพ อำเภอเมือง เชียงใหม่ 50200',
                    ),
                    const SizedBox(width: 6),
                    _buildCityChip(
                      'ภูเก็ต (ป่าตอง)',
                      7.8963,
                      98.2982,
                      'ถนนราษฎร์อุทิศ 200 ปี ตำบลป่าตอง อำเภอกะทู้ ภูเก็ต 83150',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildInputField(
          controller: _addressController,
          label: 'ที่อยู่ร้านค้าตามจริง *',
          hint: 'เลขที่, ซอย, ถนน, ตำบล, อำเภอ, จังหวัด',
          icon: Icons.place_outlined,
          maxLines: 2,
        ),

        const SizedBox(height: 22),

        // เวลาทำการ
        const Text(
          'เวลาทำการของร้าน 🕒',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(_openTimeController),
                child: AbsorbPointer(
                  child: _buildInputField(
                    controller: _openTimeController,
                    label: 'เวลาเปิดร้าน',
                    icon: Icons.access_time,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(_closeTimeController),
                child: AbsorbPointer(
                  child: _buildInputField(
                    controller: _closeTimeController,
                    label: 'เวลาปิดร้าน',
                    icon: Icons.access_time_filled,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // วันทำการ
        const Text(
          'วันเปิดให้บริการ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _operatingDays.map((day) {
            final isSelected = _selectedDays.contains(day);
            return FilterChip(
              label: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0066FF),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedDays.add(day);
                  } else {
                    if (_selectedDays.length > 1) _selectedDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Color(0xFF0066FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text(
                  'ย้อนกลับ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _goToStep3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'ถัดไป (บัญชี & เอกสาร)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: บัญชี & เอกสาร (Matches 1.5_Request_Open_Shop.png exactly!)
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. บัญชีเข้าสู่ระบบของร้าน
        const Text(
          'บัญชีเข้าสู่ระบบของร้าน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'อีเมลร้าน',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '* ห้ามใช้ซ้ำ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFCF1322),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'owner@sadaisai.com',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รหัสผ่าน',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 2. บัญชีธนาคารสำหรับรับเงิน
        const Text(
          'บัญชีธนาคารสำหรับรับเงิน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ธนาคาร',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBank,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF0066FF),
                        ),
                        items: _banks
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBank = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เลขบัญชี',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bankAccNumController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '123-4-56789-0',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ชื่อบัญชี
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ชื่อบัญชี',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bankAccNameController,
              decoration: InputDecoration(
                hintText: 'นายวิชัย ศรีสุข',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 3. เอกสารยืนยันตัวตน (PDPA)
        const Text(
          'เอกสารยืนยันตัวตน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickIdCard,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFB7EB8F), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9F7BE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF389E0D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _idCardFile != null
                            ? _idCardFile!.name
                            : 'สำเนาบัตรประชาชน.pdf',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F2B5C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'จัดเก็บแบบเข้ารหัสตาม PDPA',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF52C41A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _idCardFile != null
                        ? const Color(0xFF52C41A)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // 4. รูปถ่ายหน้าร้าน
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'รูปถ่ายหน้าร้าน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2B5C),
              ),
            ),
            Text(
              '${_shopImages.length} รูป (ขั้นต่ำ 3 รูป)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _shopImages.length >= 3
                    ? const Color(0xFF389E0D)
                    : const Color(0xFFCF1322),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photos Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Show added photos with real thumbnail preview
              ...List.generate(_shopImages.length, (idx) {
                final img = _shopImages[idx];
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FutureBuilder<Uint8List>(
                          future: img.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 14,
                      child: GestureDetector(
                        onTap: () => setState(() => _shopImages.removeAt(idx)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Button to add images
              GestureDetector(
                onTap: _pickShopImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF91CAFF),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Color(0xFF0066FF), size: 24),
                      SizedBox(height: 4),
                      Text(
                        'เพิ่มรูป',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Submit Button (Matches 1.5_Request_Open_Shop.png)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ส่งคำขอเปิดร้าน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),
        const Center(
          child: Text(
            'ตรวจสอบสถานะคำขอได้ที่เมนู "สถานะคำขอเปิดร้าน"',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Step 4: ผลลัพธ์ส่งคำขอสำเร็จ
  Widget _buildStep4Success() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB7EB8F), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF52C41A),
                size: 54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ส่งคำขอเปิดร้านสำเร็จ! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2B5C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'คำขอเปิดร้าน "${_shopNameController.text.trim()}" ถูกส่งไปยังผู้ดูแลระบบเรียบร้อยแล้ว\nเจ้าหน้าที่จะดำเนินการตรวจสอบข้อมูลและอนุมัติภายใน 1–2 วันทำการ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE58F)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.access_time_filled,
                  color: Color(0xFFFAAD14),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'สถานะปัจจุบัน: รอการอนุมัติ (Pending Verification)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD46B08),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'กลับสู่หน้าหลัก',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2B5C),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF0066FF), size: 20)
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0066FF),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleChip(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0066FF)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF0066FF)
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityChip(String label, double lat, double lng, String address) {
    final isCurrent = (_latitude == lat && _longitude == lng);
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isCurrent ? Colors.white : const Color(0xFF0F2B5C),
        ),
      ),
      backgroundColor: isCurrent ? const Color(0xFF0066FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        setState(() {
          _latitude = lat;
          _longitude = lng;
          _addressController.text = address;
        });
      },
    );
  }
}
