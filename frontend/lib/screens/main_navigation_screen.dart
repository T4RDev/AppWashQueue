import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'wallet_screen.dart';
import 'my_cars_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'owner/owner_main_navigation_screen.dart';
import 'admin/admin_main_navigation_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool isGuest;
  const MainNavigationScreen({super.key, this.isGuest = false});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = widget.isGuest || !authProvider.isAuthenticated;

    // ถ้าเป็นแอดมินหรือเจ้าของร้าน ให้แสดงหน้าแผงควบคุมของบทบาทนั้นทันที ไม่ปนกับหน้าสมาชิก
    if (!isGuest && authProvider.currentUser != null) {
      if (authProvider.currentUser!.isAdmin) {
        return const AdminMainNavigationScreen();
      }
      if (authProvider.currentUser!.isOwner) {
        return const OwnerMainNavigationScreen();
      }
    }

    final screens = [
      HomeScreen(
        isGuest: isGuest,
        onSelectTab: (index) => setState(() => _currentIndex = index),
      ),
      isGuest ? _buildGuestPrompt('กรุณาเข้าสู่ระบบเพื่อดูประวัติการจอง') : const MyBookingsScreen(),
      isGuest ? _buildGuestPrompt('กรุณาเข้าสู่ระบบเพื่อดูกระเป๋าเงินของคุณ') : const WalletScreen(),
      isGuest ? _buildGuestPrompt('กรุณาเข้าสู่ระบบเพื่อจัดการข้อมูลรถ') : const MyCarsScreen(),
      isGuest
          ? _buildGuestPrompt('กรุณาเข้าสู่ระบบเพื่อดูโปรไฟล์ของคุณ')
          : ProfileScreen(
              onSelectTab: (index) => setState(() => _currentIndex = index),
            ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textMuted,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'การจอง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'รถของฉัน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPrompt(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 56, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('เข้าสู่ระบบ / สมัครสมาชิก'),
            ),
          ],
        ),
      ),
    );
  }
}

