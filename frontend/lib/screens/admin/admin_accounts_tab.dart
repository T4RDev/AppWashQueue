import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class AdminAccountsTab extends StatefulWidget {
  const AdminAccountsTab({super.key});

  @override
  State<AdminAccountsTab> createState() => _AdminAccountsTabState();
}

class _AdminAccountsTabState extends State<AdminAccountsTab> {
  final ApiService _api = ApiService();
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;

  String _currentType = 'shops'; // 'shops' or 'members'
  List<dynamic> _users = [];
  List<dynamic> _shops = [];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final uRes = await _api.get(ApiConstants.adminUsers);
      if (uRes.success && uRes.data != null) {
        _users = uRes.data is List ? uRes.data : [];
      }

      final sRes = await _api.get(ApiConstants.adminShops);
      if (sRes.success && sRes.data != null) {
        _shops = sRes.data is List ? sRes.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleUserStatus(int userId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    final res = await _api.patch(
      '${ApiConstants.adminUsers}/$userId/status',
      body: {'status': newStatus},
    );
    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(context, newStatus == 'active' ? 'ปลดระงับบัญชีเรียบร้อย' : 'ระงับบัญชีเรียบร้อย');
      _fetchAccounts();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchCtrl.text.toLowerCase();

    final filteredShops = _shops.where((s) {
      final name = (s['shop_name'] ?? '').toString().toLowerCase();
      final phone = (s['phone'] ?? '').toString().toLowerCase();
      final email = (s['owner_email'] ?? '').toString().toLowerCase();
      return name.contains(search) || phone.contains(search) || email.contains(search);
    }).toList();

    final filteredMembers = _users.where((u) {
      if (u['role'] == 'admin') return false;
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(search) || phone.contains(search) || email.contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header (Matches 4.2_Accounts_Permissions.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: const [
                  Text('จัดการบัญชี', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
            ),

            // Search Bar (Matches 4.2_Accounts_Permissions.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'ค้นหาชื่อร้าน อีเมล หรือเบอร์โทร',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Segment Tabs (Matches 4.2_Accounts_Permissions.png)
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
                    _buildSegmentTab('shops', 'ร้านล้างรถ (${filteredShops.length})'),
                    _buildSegmentTab('members', 'สมาชิก (${filteredMembers.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchAccounts,
                      child: _currentType == 'shops'
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredShops.length,
                              itemBuilder: (ctx, i) => _buildShopAccountCard(filteredShops[i]),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredMembers.length,
                              itemBuilder: (ctx, i) => _buildMemberAccountCard(filteredMembers[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String key, String label) {
    final isSelected = _currentType == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentType = key),
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

  Widget _buildShopAccountCard(dynamic shop) {
    final shopName = shop['shop_name'] ?? 'คาร์แคร์ สะอาดใส';
    final email = shop['owner_email'] ?? shop['email'] ?? 'owner@washq.com';
    final status = shop['status'] ?? 'approved';
    final isActive = status == 'approved';
    final ownerId = shop['owner_id'] ?? 0;

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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFF6FFED) : const Color(0xFFFFF2F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? const Color(0xFF52C41A) : const Color(0xFFF5222D))),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'ใช้งานอยู่' : 'ถูกระงับ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF389E0D) : const Color(0xFFCF1322)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Permission Toggles (Matches 4.2_Accounts_Permissions.png)
          const Text('สิทธิ์การเข้าถึง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),

          _buildPermissionRow('แสดงร้านบนแอปพลิเคชัน', 'ลูกค้าค้นหาและดูร้านได้', true),
          _buildPermissionRow('รับการจองคิว', 'เปิดให้ลูกค้าจองสล็อต', true),
          _buildPermissionRow('แก้ไขราคา & สล็อต', 'เจ้าของร้านจัดการเองได้', true),
          const SizedBox(height: 14),

          // Action Buttons: แก้ไขข้อมูล vs ระงับบัญชี (Matches 4.2_Accounts_Permissions.png)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    AppSnackBar.showSuccess(context, 'เปิดดูข้อมูลร้าน $shopName');
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('แก้ไขข้อมูล', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? const Color(0xFFFFF2F0) : const Color(0xFFF6FFED),
                    foregroundColor: isActive ? const Color(0xFFCF1322) : const Color(0xFF389E0D),
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _toggleUserStatus(ownerId, isActive ? 'active' : 'suspended'),
                  icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 16),
                  label: Text(isActive ? 'ระงับบัญชี' : 'ปลดระงับ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAccountCard(dynamic member) {
    final name = member['full_name'] ?? 'ผู้ใช้งาน';
    final email = member['email'] ?? '';
    final phone = member['phone'] ?? '';
    final status = member['status'] ?? 'active';
    final isActive = status == 'active';
    final userId = member['id'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF722ED1).withOpacity(0.15),
            foregroundColor: const Color(0xFF722ED1),
            child: Text(name.isNotEmpty ? name.substring(0, 1) : 'U', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$email • $phone', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? const Color(0xFFFFF2F0) : const Color(0xFFF6FFED),
              foregroundColor: isActive ? const Color(0xFFCF1322) : const Color(0xFF389E0D),
              elevation: 0,
              minimumSize: const Size(70, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _toggleUserStatus(userId, status),
            child: Text(isActive ? 'ระงับ' : 'ปลดระงับ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String title, String desc, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              activeColor: const Color(0xFF00B96B),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}
