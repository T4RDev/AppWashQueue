import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'admin_overview_tab.dart';
import 'admin_shop_requests_tab.dart';
import 'admin_withdrawals_tab.dart';
import 'admin_accounts_tab.dart';
import 'admin_settings_tab.dart';

class AdminMainNavigationScreen extends StatefulWidget {
  const AdminMainNavigationScreen({super.key});

  @override
  State<AdminMainNavigationScreen> createState() => _AdminMainNavigationScreenState();
}

class _AdminMainNavigationScreenState extends State<AdminMainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminOverviewTab(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const AdminShopRequestsTab(),
      const AdminWithdrawalsTab(),
      const AdminAccountsTab(),
      const AdminSettingsTab(),
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'ภาพรวม',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'คำขอร้าน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_upward),
            activeIcon: Icon(Icons.arrow_upward),
            label: 'การถอน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'บัญชี',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}

