import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class AdminWithdrawalsTab extends StatefulWidget {
  const AdminWithdrawalsTab({super.key});

  @override
  State<AdminWithdrawalsTab> createState() => _AdminWithdrawalsTabState();
}

class _AdminWithdrawalsTabState extends State<AdminWithdrawalsTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _withdrawals = [];
  String _currentFilter = 'pending'; // 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _fetchWithdrawals();
  }

  Future<void> _fetchWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(ApiConstants.adminWithdrawals);
      if (res.success && res.data != null) {
        _withdrawals = res.data is List ? res.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredWithdrawals {
    return _withdrawals.where((w) => w['status'] == _currentFilter).toList();
  }

  int get _pendingCount {
    return _withdrawals.where((w) => w['status'] == 'pending').length;
  }

  Future<void> _processWithdrawal(int id, String status) async {
    final res = await _api.patch(
      '${ApiConstants.adminWithdrawals}/$id/process',
      body: {'status': status, 'admin_notes': status == 'approved' ? 'โอนเงินเรียบร้อย' : 'ข้อมูลบัญชีไม่ถูกต้อง'},
    );
    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(
        context,
        status == 'approved' ? 'อนุมัติการโอนเงินแล้ว' : 'ปฏิเสธและคืนเครดิตเข้ากระเป๋าแล้ว',
      );
      _fetchWithdrawals();
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
            // Top Header (Matches 4.3_Withdraw_Requests.png)
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
                      Text('คำขอถอนเครดิต', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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

            // Segmented Filter Tabs (Matches 4.3_Withdraw_Requests.png)
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
                    _buildSegmentTab('rejected', 'ไม่อนุมัติ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Withdrawal List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchWithdrawals,
                      child: _filteredWithdrawals.isEmpty
                          ? Center(
                              child: Text(
                                _currentFilter == 'pending' ? 'ไม่มีคำขอถอนเครดิตที่รออนุมัติ' : 'ไม่มีรายการในหมวดนี้',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filteredWithdrawals.length,
                              itemBuilder: (ctx, i) => _buildWithdrawalCard(_filteredWithdrawals[i]),
                            ),
                    ),
            ),

            // Note at bottom (Matches 4.3_Withdraw_Requests.png)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Center(
                child: Text(
                  'หากไม่อนุมัติ ระบบจะคืนเครดิตเข้า Wallet ของผู้ยื่นคำขออัตโนมัติ',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

  Widget _buildWithdrawalCard(dynamic w) {
    final id = w['id'] ?? 0;
    final role = w['role'] ?? 'owner';
    final name = w['full_name'] ?? (role == 'owner' ? 'คาร์แคร์ สะอาดใส' : 'สมชาย ใจดี');
    final date = w['created_at']?.toString().substring(0, 10) ?? '25 ต.ค. 69';
    final amount = double.tryParse(w['amount']?.toString() ?? '0') ?? 0;
    final fee = double.tryParse(w['fee']?.toString() ?? '0') ?? (role == 'owner' ? amount * 0.05 : 0.0);
    final netAmount = double.tryParse(w['net_amount']?.toString() ?? '0') ?? (amount - fee);
    final bankName = w['bank_name'] ?? 'กสิกรไทย';
    final bankAccNum = w['bank_account_number'] ?? '123-4-56789-0';
    final bankAccName = w['bank_account_name'] ?? name;
    final status = w['status'] ?? 'pending';

    final isOwner = role == 'owner';

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
          // Top Row: User Icon, Name, Role Tag, Date, Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isOwner ? AppTheme.primaryColor : const Color(0xFF722ED1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(isOwner ? Icons.storefront : Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text('${isOwner ? 'ร้านค้า' : 'สมาชิก'} • ยื่นเมื่อ $date', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
                  status == 'pending' ? 'รออนุมัติ' : status == 'approved' ? 'อนุมัติแล้ว' : 'ไม่อนุมัติ',
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
          const SizedBox(height: 14),

          // Detail Box (Matches 4.3_Withdraw_Requests.png)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดถอน', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('${amount.toStringAsFixed(0)} เครดิต', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ค่าธรรมเนียม 5%', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text(
                      fee > 0 ? '- ฿${fee.toStringAsFixed(2)}' : 'ไม่มี',
                      style: TextStyle(color: fee > 0 ? Colors.redAccent : const Color(0xFF389E0D), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดโอนจริง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('฿${netAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bank Info
          Row(
            children: [
              const Icon(Icons.account_balance, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$bankName • $bankAccNum • $bankAccName',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: ไม่อนุมัติ vs อนุมัติและโอนแล้ว (Matches 4.3_Withdraw_Requests.png)
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
                    onPressed: () => _processWithdrawal(id, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('ไม่อนุมัติ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    onPressed: () => _processWithdrawal(id, 'approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('อนุมัติและโอนแล้ว', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
