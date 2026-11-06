import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class AdminShopRequestsTab extends StatefulWidget {
  const AdminShopRequestsTab({super.key});

  @override
  State<AdminShopRequestsTab> createState() => _AdminShopRequestsTabState();
}

class _AdminShopRequestsTabState extends State<AdminShopRequestsTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _shops = [];
  String _currentFilter = 'pending'; // 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.adminShops);
      if (res.success && res.data != null) {
        _shops = res.data is List ? res.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredShops {
    return _shops.where((s) => s['status'] == _currentFilter).toList();
  }

  int get _pendingCount {
    return _shops.where((s) => s['status'] == 'pending').length;
  }

  Future<void> _updateShopStatus(int shopId, String newStatus) async {
    final res = await _api.patch(
      '${ApiConstants.adminShops}/$shopId/status',
      body: {'status': newStatus},
    );
    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(
        context,
        newStatus == 'approved' ? 'อนุมัติร้านค้าเรียบร้อยแล้ว' : 'ปฏิเสธคำขอเปิดร้านแล้ว',
      );
      _fetchShops();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header (Matches 4.1_Shop_Requests.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ผู้ดูแลระบบ', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      SizedBox(height: 2),
                      Text('คำขอเปิดร้าน', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF103B7B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // Segmented Filter Tabs (Matches 4.1_Shop_Requests.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegmentTab('pending', 'รออนุมัติ ($_pendingCount)'),
                    _buildSegmentTab('approved', 'อนุมัติแล้ว'),
                    _buildSegmentTab('rejected', 'ปฏิเสธ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shop List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchShops,
                      child: _filteredShops.isEmpty
                          ? Center(
                              child: Text(
                                _currentFilter == 'pending' ? 'ไม่มีคำขอเปิดร้านที่รออนุมัติ' : 'ไม่มีรายการในหมวดนี้',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filteredShops.length,
                              itemBuilder: (ctx, i) => _buildShopRequestCard(_filteredShops[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String key, String label) {
    final isSelected = _currentFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopRequestCard(dynamic shop) {
    final shopId = shop['id'] ?? 0;
    final shopName = shop['shop_name'] ?? 'ร้านคาร์แคร์';
    final ownerName = shop['owner_name'] ?? shop['full_name'] ?? 'ผู้ยื่นคำขอ';
    final createdDate = shop['created_at']?.toString().substring(0, 10) ?? '25 ต.ค. 2569';
    final openTime = (shop['open_time'] ?? '08:00').toString().substring(0, 5);
    final closeTime = (shop['close_time'] ?? '18:00').toString().substring(0, 5);
    final status = shop['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon, Name, Date, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text('ผู้ยื่น: $ownerName', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('ยื่นเมื่อ $createdDate', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending'
                      ? const Color(0xFFFFF7E6)
                      : status == 'approved'
                          ? const Color(0xFFF6FFED)
                          : const Color(0xFFFFF2F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'pending' ? 'รอตรวจสอบ' : status == 'approved' ? 'อนุมัติแล้ว' : 'ปฏิเสธ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status == 'pending'
                        ? const Color(0xFFD46B08)
                        : status == 'approved'
                            ? const Color(0xFF389E0D)
                            : const Color(0xFFCF1322),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips (Vehicle types & opening hours)
          Wrap(
            spacing: 6,
            children: [
              _buildTag('รถยนต์'),
              _buildTag('จักรยานยนต์'),
              _buildTag('$openTime–$closeTime'),
            ],
          ),
          const SizedBox(height: 12),

          // PDPA & Photo verification indicators (Matches 4.1_Shop_Requests.png)
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFF389E0D), size: 16),
              SizedBox(width: 4),
              Text('บัตร ปชช. (เข้ารหัสแล้ว)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              SizedBox(width: 14),
              Icon(Icons.photo_library_outlined, color: Color(0xFF389E0D), size: 16),
              SizedBox(width: 4),
              Text('รูปหน้าร้านแนบแล้ว', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: ปฏิเสธ vs อนุมัติ (Matches 4.1_Shop_Requests.png)
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF2F0),
                      foregroundColor: const Color(0xFFCF1322),
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _updateShopStatus(shopId, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('ปฏิเสธ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _updateShopStatus(shopId, 'approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('อนุมัติ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
    );
  }
}
