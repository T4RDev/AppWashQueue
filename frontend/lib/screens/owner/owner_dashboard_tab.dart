import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import 'owner_stats_screen.dart';

class OwnerDashboardTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  const OwnerDashboardTab({super.key, this.onNavigateTab});

  @override
  State<OwnerDashboardTab> createState() => _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends State<OwnerDashboardTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'today_queue': 0,
    'waiting': 0,
    'today_income': 0,
    'wallet_balance': 0.0,
    'pending_balance': 0.0,
    'shop_name': 'คาร์แคร์ของฉัน',
  };
  List<dynamic> _todayBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch stats
      final statsRes = await _api.get(ApiConstants.ownerStats);
      if (statsRes.success && statsRes.data != null) {
        _stats = Map<String, dynamic>.from(statsRes.data);
      }

      // 2. Fetch today's bookings
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final bookingsRes = await _api.get('${ApiConstants.ownerBookings}?booking_date=$todayStr');
      if (bookingsRes.success && bookingsRes.data != null) {
        _todayBookings = bookingsRes.data is List ? bookingsRes.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(int bookingId, String newStatus) async {
    final res = await _api.patch(
      '${ApiConstants.ownerBookings}/$bookingId/status',
      body: {'status': newStatus},
    );
    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(context, 'อัปเดตสถานะสำเร็จ');
      _fetchDashboardData();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final shopName = _stats['shop_name'] ?? user?.shopName ?? 'คาร์แคร์ของฉัน';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Dark Blue Header (Matches 3.1_Owner_Dashboard.png)
              Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 28),
                decoration: const BoxDecoration(
                  color: Color(0xFF103B7B),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'แดชบอร์ดร้าน',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shopName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                                tooltip: 'สถิติร้าน',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const OwnerStatsScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${_stats['waiting'] ?? 0}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3 Stat Cards in a row
                    Row(
                      children: [
                        _buildStatBox('คิววันนี้', '${_stats['today_queue'] ?? 0}'),
                        const SizedBox(width: 10),
                        _buildStatBox('รอเข้ารับบริการ', '${_stats['waiting'] ?? 0}'),
                        const SizedBox(width: 10),
                        _buildStatBox('รายได้วันนี้', '฿${_stats['today_income'] ?? 0}'),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Credit Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFD48806), size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('เครดิตร้านใน Wallet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(
                                  '${((_stats['wallet_balance'] ?? 0) as num).toStringAsFixed(0)} เครดิต',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE6F4FF),
                              foregroundColor: AppTheme.primaryColor,
                              elevation: 0,
                              minimumSize: const Size(80, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () => widget.onNavigateTab?.call(3), // ไปแท็บ Wallet
                            child: const Text('ถอนเงิน', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Today's Queue Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'คิววันนี้ • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year + 543}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab?.call(1),
                          child: const Text('ดูทั้งหมด'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Booking Queue Cards
                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                    else if (_todayBookings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.event_available, size: 48, color: AppTheme.textMuted),
                              SizedBox(height: 8),
                              Text('ยังไม่มีคิวจองในวันนี้', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._todayBookings.map((b) => _buildBookingCard(b)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 6),
            Text(
              val,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(dynamic b) {
    final status = b['status']?.toString() ?? 'pending';
    final startTime = (b['start_time'] ?? '08:00').toString().substring(0, 5);
    final endTime = (b['end_time'] ?? '10:00').toString().substring(0, 5);
    final plate = b['plate_number'] ?? 'กข 1234';
    final vehicleType = b['vehicle_type'] ?? 'car';
    final serviceName = b['service_name'] ?? 'ล้างอัดฉีด';
    final bookingId = b['id'] ?? 0;

    String statusText;
    Color statusBg;
    Color statusColor;

    switch (status) {
      case 'confirmed':
        statusText = 'ยืนยันแล้ว';
        statusBg = const Color(0xFFE6F4FF);
        statusColor = const Color(0xFF0958D9);
        break;
      case 'in_progress':
        statusText = 'กำลังให้บริการ';
        statusBg = const Color(0xFFFFFBE6);
        statusColor = const Color(0xFFD46B08);
        break;
      case 'completed':
        statusText = 'เสร็จสิ้น';
        statusBg = const Color(0xFFF6FFED);
        statusColor = const Color(0xFF389E0D);
        break;
      case 'no_show':
        statusText = 'ไม่มาตามนัด';
        statusBg = const Color(0xFFFFF2F0);
        statusColor = const Color(0xFFCF1322);
        break;
      default:
        statusText = status;
        statusBg = Colors.grey.shade100;
        statusColor = Colors.grey.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(startTime, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13)),
                    Text('-$endTime', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$plate • $vehicleType',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceName,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons depending on status (Matches 3.1_Owner_Dashboard.png)
          if (status == 'confirmed')
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(bookingId, 'in_progress'),
                    child: const Text('รับรถเข้าบริการ', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF2F0),
                      foregroundColor: const Color(0xFFCF1322),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(bookingId, 'no_show'),
                    child: const Text('ไม่มาตามนัด', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )
          else if (status == 'in_progress')
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B96B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => _updateStatus(bookingId, 'completed'),
              child: const Text('บริการเสร็จสิ้น ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
        ],
      ),
    );
  }
}

