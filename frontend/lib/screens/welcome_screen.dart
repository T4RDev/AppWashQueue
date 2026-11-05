import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'register_shop_screen.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),
              // Header & Logo
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_car_wash_rounded,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ยินดีต้อนรับสู่ WashQ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'จองคิวล้างรถง่ายๆ รวดเร็ว ไม่ต้องรอคิว\nค้นหาร้านคาร์แคร์ใกล้คุณและชำระเงินอย่างปลอดภัย',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('สมัครสมาชิก'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      // 1.3.1 (2) ค้นหาร้านล้างรถได้โดยไม่ต้องเข้าสู่ระบบ
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigationScreen(isGuest: true)),
                      );
                    },
                    icon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    label: const Text(
                      'ค้นหาร้านล้างรถโดยไม่เข้าสู่ระบบ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                  const Divider(height: 32),
                  TextButton(
                    onPressed: () {
                      // 1.3.1 (4) สมัครเป็นร้านล้างรถ
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterShopScreen()),
                      );
                    },
                    child: const Text(
                      'คุณเป็นเจ้าของร้านคาร์แคร์? สมัครเปิดร้านกับเรา',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

