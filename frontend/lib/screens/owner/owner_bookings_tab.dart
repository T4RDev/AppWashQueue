import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class OwnerBookingsTab extends StatefulWidget {
  const OwnerBookingsTab({super.key});

  @override
  State<OwnerBookingsTab> createState() => _OwnerBookingsTabState();
}

class _OwnerBookingsTabState extends State<OwnerBookingsTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.ownerBookings);
      if (res.success && res.data != null) {
        _bookings = res.data is List ? res.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredBookings {
    if (_selectedStatus == 'all') return _bookings;
    return _bookings.where((b) => b['status'] == _selectedStatus).toList();
  }

  Future<void> _updateStatus(int bookingId, String newStatus) async {
    final res = await _api.patch(
      '${ApiConstants.ownerBookings}/$bookingId/status',
      body: {'status': newStatus},
    );
    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(context, 'อัปเดตสถานะสำเร็จ');
      _fetchBookings();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  void _showQrCheckInDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner, color: Color(0xFF0066FF)),
            SizedBox(width: 8),
            Text(
              'เช็คอินคิวลูกค้า',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กรอกรหัสคิว หรือสแกน QR Code ของลูกค้าเพื่อเช็คอิน',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'เช่น #WQ-00001 หรือ 1',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final raw = codeController.text.trim().replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              final id = int.tryParse(raw);
              if (id == null) {
                AppSnackBar.showError(context, 'รหัสคิวไม่ถูกต้อง');
                return;
              }
              Navigator.pop(ctx);
              _updateStatus(id, 'in_service');
            },
            child: const Text(
              'เช็คอินเริ่มล้าง',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'จัดการคิวร้านค้า',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0066FF)),
            tooltip: 'เช็คอินคิวด้วย QR',
            onPressed: _showQrCheckInDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'ทั้งหมด (${_bookings.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('confirmed', 'ยืนยันแล้ว'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'กำลังล้าง'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'เสร็จสิ้น'),
                const SizedBox(width: 8),
                _buildFilterChip('no_show', 'ไม่มาตามนัด'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchBookings,
                    child: _filteredBookings.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่พบรายการจองตามเงื่อนไข',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _filteredBookings.length,
                            itemBuilder: (ctx, i) =>
                                _buildBookingItem(_filteredBookings[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedStatus = key),
    );
  }

  Widget _buildBookingItem(dynamic b) {
    final bookingId = b['id'] ?? 0;
    final date = b['booking_date']?.toString().substring(0, 10) ?? '';
    final startTime = (b['start_time'] ?? '08:00').toString().substring(0, 5);
    final endTime = (b['end_time'] ?? '10:00').toString().substring(0, 5);
    final plate = b['plate_number'] ?? 'กข 1234';
    final vehicleType = b['vehicle_type'] ?? 'car';
    final serviceName = b['service_name'] ?? 'บริการล้างรถ';
    final total = b['total_price'] ?? 0;
    final status = b['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$date • $startTime - $endTime น.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                '฿$total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$plate ($vehicleType) • $serviceName',
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'confirmed') ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(110, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _updateStatus(bookingId, 'in_progress'),
                  child: const Text(
                    'รับรถเข้าบริการ',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    minimumSize: const Size(90, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _updateStatus(bookingId, 'no_show'),
                  child: const Text(
                    'ไม่มาตามนัด',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ] else if (status == 'in_progress') ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B96B),
                    minimumSize: const Size(120, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _updateStatus(bookingId, 'completed'),
                  child: const Text(
                    'บริการเสร็จสิ้น ✓',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
