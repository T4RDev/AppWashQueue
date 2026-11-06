import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Optional Car Info (1.3.1 ข้อ 1)
  bool _includeVehicle = true;
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  String _selectedVehicleType = 'car';

  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    List<Map<String, dynamic>>? vehicles;
    if (_includeVehicle && _plateController.text.trim().isNotEmpty) {
      vehicles = [
        {
          'plate_number': _plateController.text.trim(),
          'vehicle_type': _selectedVehicleType,
          'brand': _brandController.text.trim().isEmpty
              ? '-'
              : _brandController.text.trim(),
          'model': _modelController.text.trim().isEmpty
              ? '-'
              : _modelController.text.trim(),
        },
      ];
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicles: vehicles,
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(
        context,
        'สมัครสมาชิกสำเร็จ ยินดีต้อนรับสู่ WashQ!',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      AppSnackBar.showError(
        context,
        authProvider.errorMessage ?? 'สมัครสมาชิกไม่สำเร็จ',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'สร้างบัญชีสมาชิกใหม่ 🚗',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'กรอกข้อมูลส่วนตัวเพื่อเริ่มต้นใช้งานและจองคิว',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ - นามสกุล',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'กรุณากรอกชื่อ-สกุล'
                      : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล (Email ไม่ซ้ำกัน)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
                    if (!v.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์ (ไม่ซ้ำกัน)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'กรุณากรอกเบอร์โทรศัพท์'
                      : null,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน (Password)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'
                      : null,
                ),
                const SizedBox(height: 20),

                // Section: Vehicle Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ข้อมูลรถของคุณ (เพิ่มได้ภายหลัง)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _includeVehicle,
                              onChanged: (val) =>
                                  setState(() => _includeVehicle = val),
                            ),
                          ],
                        ),
                        if (_includeVehicle) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _plateController,
                            decoration: const InputDecoration(
                              labelText: 'ทะเบียนรถ (เช่น กข-1234 กทม)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedVehicleType,
                            decoration: const InputDecoration(
                              labelText: 'ประเภทรถ',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'car',
                                child: Text('รถยนต์'),
                              ),
                              DropdownMenuItem(
                                value: 'suv',
                                child: Text('รถ SUV'),
                              ),
                              DropdownMenuItem(
                                value: 'motorcycle',
                                child: Text('รถจักรยานยนต์'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedVehicleType = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(
                                    labelText: 'ยี่ห้อ (Brand)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _modelController,
                                  decoration: const InputDecoration(
                                    labelText: 'รุ่น (Model)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleRegister,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('ยืนยันการสมัครสมาชิก'),
                ),
                const SizedBox(height: 16),

                // Link to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'มีบัญชีอยู่แล้ว? ',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
