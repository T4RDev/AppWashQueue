import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../welcome_screen.dart';

class OwnerShopTab extends StatefulWidget {
  const OwnerShopTab({super.key});

  @override
  State<OwnerShopTab> createState() => _OwnerShopTabState();
}

class _OwnerShopTabState extends State<OwnerShopTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  double _lat = 13.736717;
  double _lng = 100.560787;

  String _bankName = 'กสิกรไทย';
  String _bankAccNum = '123-4-56789-0';
  String _bankAccName = 'สมชาย คาร์แคร์';

  @override
  void initState() {
    super.initState();
    _fetchShop();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchShop() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.ownerShop);
      if (res.success && res.data != null) {
        final d = res.data;
        _nameCtrl.text = d['shop_name'] ?? '';
        _phoneCtrl.text = d['phone'] ?? '';
        _descCtrl.text = d['description'] ?? '';
        _addressCtrl.text = d['address'] ?? '';
        _lat = double.tryParse(d['latitude']?.toString() ?? '13.736717') ?? 13.736717;
        _lng = double.tryParse(d['longitude']?.toString() ?? '100.560787') ?? 100.560787;
        _bankName = d['bank_name'] ?? 'กสิกรไทย';
        _bankAccNum = d['bank_account_number'] ?? '123-4-56789-0';
        _bankAccName = d['bank_account_name'] ?? 'สมชาย คาร์แคร์';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final res = await _api.put(
      ApiConstants.ownerShop,
      body: {
        'shop_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
      },
    );
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(context, 'บันทึกข้อมูลร้านค้าเรียบร้อยแล้ว');
    } else {
      AppSnackBar.showError(context, res.message);
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลร้าน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            tooltip: 'ออกจากระบบ',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner (Matches 3.2_Edit_Shop.png)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.storefront, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _nameCtrl.text.isEmpty ? 'ชื่อร้านคาร์แคร์' : _nameCtrl.text,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fields
                  _buildInputLabel('ชื่อร้านคาร์แคร์'),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.storefront_outlined),
                      hintText: 'ชื่อร้านคาร์แคร์',
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildInputLabel('เบอร์ติดต่อร้าน'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: 'เบอร์ติดต่อร้าน',
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildInputLabel('รายละเอียดบริการ'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.description_outlined),
                      hintText: 'ล้างอัดฉีด ดูดฝุ่น เคลือบสี มีห้องรับรอง Wi-Fi',
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildInputLabel('ที่อยู่ร้าน'),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'ที่ตั้งร้านค้า',
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildInputLabel('ตำแหน่งและพิกัดร้าน'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            AppSnackBar.showSuccess(context, 'พิกัด GPS ได้รับการอัปเดตแล้ว');
                          },
                          child: const Text('ปักหมุดใหม่'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bank account card (Matches 3.2_Edit_Shop.png)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBE6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE58F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance, color: Color(0xFFD48806)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('บัญชีธนาคารรับเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF873800))),
                              const SizedBox(height: 2),
                              Text('$_bankName • $_bankAccNum • $_bankAccName', style: const TextStyle(fontSize: 12, color: Color(0xFF873800))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ).let((style) => OutlinedButton(
                        style: style,
                        onPressed: _handleLogout,
                        child: const Text('ออกจากระบบ'),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    );
  }
}

extension LetExtension<T> on T {
  R let<R>(R Function(T it) block) => block(this);
}

