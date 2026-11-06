import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';

class AdminOverviewTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  const AdminOverviewTab({super.key, this.onNavigateTab});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _overview = {
    'platform_fee_income': 12480,
    'fee_withdraw_count': 41,
    'total_credits': 186350,
    'monthly_bookings': 2914,
    'completed_bookings': 2702,
    'total_members': 1248,
    'new_members_this_month': 96,
    'total_shops': 38,
    'pending_shops': 4,
    'pending_withdrawals': 5,
  };

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.adminOverview);
      if (res.success && res.data != null) {
        _overview = Map<String, dynamic>.from(res.data);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchOverview,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header (Matches 4.4_Admin_Overview.png)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ผู้ดูแลระบบ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ภาพรวมแพลตฟอร์ม',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'พ.ย. 2569',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Big Gradient Fee Revenue Card (Matches 4.4_Admin_Overview.png)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายได้จากค่าธรรมเนียม (5%)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '฿${((_overview['platform_fee_income'] ?? 0) as num).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'จากการถอนเงินของร้าน ${_overview['fee_withdraw_count'] ?? 0} รายการ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2x2 Stat Cards Grid (Matches 4.4_Admin_Overview.png)
                Row(
                  children: [
                    Expanded(
                      child: _buildGridCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFFD48806),
                        title: 'เครดิตคงค้างในระบบ',
                        value: ((_overview['total_credits'] ?? 0) as num)
                            .toStringAsFixed(0),
                        subtitle: 'รวม Wallet สมาชิกและร้าน',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildGridCard(
                        icon: Icons.calendar_today_outlined,
                        iconColor: AppTheme.primaryColor,
                        title: 'การจองเดือนนี้',
                        value: '${_overview['monthly_bookings'] ?? 0}',
                        subtitle:
                            'เสร็จสิ้น ${_overview['completed_bookings'] ?? 0} รายการ',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildGridCard(
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF722ED1),
                        title: 'สมาชิก',
                        value: '${_overview['total_members'] ?? 0}',
                        subtitle:
                            'ใหม่เดือนนี้ +${_overview['new_members_this_month'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildGridCard(
                        icon: Icons.storefront_outlined,
                        iconColor: const Color(0xFF389E0D),
                        title: 'ร้านล้างรถ',
                        value: '${_overview['total_shops'] ?? 0}',
                        subtitle:
                            'รออนุมัติ ${_overview['pending_shops'] ?? 0} ร้าน',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section "รอดำเนินการ" (Matches 4.4_Admin_Overview.png)
                const Text(
                  'รอดำเนินการ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Action Item 1: คำขอเปิดร้าน
                InkWell(
                  onTap: () => widget.onNavigateTab?.call(1), // ไปแท็บคำขอร้าน
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'คำขอเปิดร้าน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_overview['pending_shops'] ?? 0} รายการ',
                            style: const TextStyle(
                              color: Color(0xFFD46B08),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Action Item 2: คำขอถอนเครดิต
                InkWell(
                  onTap: () => widget.onNavigateTab?.call(2), // ไปแท็บการถอน
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'คำขอถอนเครดิต',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_overview['pending_withdrawals'] ?? 0} รายการ',
                            style: const TextStyle(
                              color: Color(0xFFD46B08),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Promo Card (Matches 4.4_Admin_Overview.png)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.percent,
                          color: Color(0xFFD48806),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ยกเว้นค่าธรรมเนียม 1 เดือนแรก',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'โปรโมชั่นร้านใหม่ • ใช้อยู่ 6 ร้าน',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6F4FF),
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          minimumSize: const Size(70, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => widget.onNavigateTab?.call(4),
                        child: const Text(
                          '+ สร้าง',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
