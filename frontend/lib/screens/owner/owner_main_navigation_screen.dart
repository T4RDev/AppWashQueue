import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'owner_dashboard_tab.dart';
import 'owner_bookings_tab.dart';
import 'owner_slots_tab.dart';
import 'owner_wallet_tab.dart';
import 'owner_shop_tab.dart';

class OwnerMainNavigationScreen extends StatefulWidget {
  const OwnerMainNavigationScreen({super.key});

  @override
  State<OwnerMainNavigationScreen> createState() => _OwnerMainNavigationScreenState();
}

class _OwnerMainNavigationScreenState extends State<OwnerMainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      OwnerDashboardTab(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const OwnerBookingsTab(),
      const OwnerSlotsTab(),
      const OwnerWalletTab(),
      const OwnerShopTab(),
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
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'การจอง',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time_filled),
            label: 'สล็อต',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'ร้านของฉัน',
          ),
        ],
      ),
    );
  }
}

