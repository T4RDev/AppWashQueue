import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../welcome_screen.dart';

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _discounts = [];

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.adminDiscounts);
      if (res.success && res.data != null) {
        _discounts = res.data is List ? res.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showCreateDiscountDialog() {
    final codeCtrl = TextEditingController();
    final percentCtrl = TextEditingController(text: '10');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('สร้างโค้ดส่วนลดใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'โค้ดส่วนลด (เช่น WASH10)')),
            const SizedBox(height: 10),
            TextField(controller: percentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'เปอร์เซ็นต์ส่วนลด (%)')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'คำอธิบาย (เช่น ส่วนลดต้อนรับสมาชิกใหม่)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _api.post(
                ApiConstants.adminDiscounts,
                body: {
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'discount_percent': double.tryParse(percentCtrl.text) ?? 10,
                  'description': descCtrl.text.trim(),
                },
              );
              if (!mounted) return;
              if (res.success) {
                AppSnackBar.showSuccess(context, 'สร้างโค้ดส่วนลดเรียบร้อย');
                _fetchDiscounts();
              } else {
                AppSnackBar.showError(context, res.message);
              }
            },
            child: const Text('สร้างโค้ด'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบ & แอดมิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF103B7B),
                    child: Icon(Icons.shield, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'System Administrator', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? 'admin@washqueue.com', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE6F4FF), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Admin', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Platform Fee Configuration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.percent, color: Color(0xFFD48806), size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('อัตราค่าธรรมเนียมถอนเงินของร้านค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('คิด 5% จากยอดถอนเข้าบัญชี (แพลตฟอร์ม WashQ)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Text('5.0%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Discount Codes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('โค้ดส่วนลดของระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(100, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: _showCreateDiscountDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('สร้างโค้ด', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_discounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('ยังไม่มีโค้ดส่วนลดที่สร้างไว้', style: TextStyle(color: AppTheme.textSecondary))),
              )
            else
              ..._discounts.map((d) {
                final code = d['code'] ?? '';
                final percent = d['discount_percent'] ?? 0;
                final desc = d['description'] ?? '';
                final isActive = d['is_active'] == 1 || d['is_active'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD591)),
                        ),
                        child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD46B08), fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ลด $percent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF00B96B),
                        onChanged: (val) async {
                          final id = d['id'] ?? 0;
                          final res = await _api.patch('${ApiConstants.adminDiscounts}/$id/status', body: {'is_active': val});
                          if (res.success) _fetchDiscounts();
                        },
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
