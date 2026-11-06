import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class OwnerWalletTab extends StatefulWidget {
  const OwnerWalletTab({super.key});

  @override
  State<OwnerWalletTab> createState() => _OwnerWalletTabState();
}

class _OwnerWalletTabState extends State<OwnerWalletTab> {
  final ApiService _api = ApiService();
  final _amountCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  double _balance = 0.0;
  double _pendingBalance = 0.0;
  Map<String, dynamic> _shop = {};
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch wallet
      final wRes = await _api.get(ApiConstants.wallet);
      if (wRes.success && wRes.data != null) {
        _balance =
            double.tryParse(
              wRes.data['wallet']['balance']?.toString() ?? '0',
            ) ??
            0.0;
        _pendingBalance =
            double.tryParse(
              wRes.data['wallet']['pending_balance']?.toString() ?? '0',
            ) ??
            0.0;
        _transactions = wRes.data['transactions'] is List
            ? wRes.data['transactions']
            : [];
      }

      // 2. Fetch shop bank info
      final sRes = await _api.get(ApiConstants.ownerShop);
      if (sRes.success && sRes.data != null) {
        _shop = Map<String, dynamic>.from(sRes.data);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleWithdraw() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      AppSnackBar.showError(context, 'กรุณาระบุจำนวนเครดิตที่ต้องการถอน');
      return;
    }
    if (amount > _balance) {
      AppSnackBar.showError(context, 'ยอดเครดิตคงเหลือไม่เพียงพอ');
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await _api.post(
      ApiConstants.ownerWithdraw,
      body: {'amount': amount},
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(
        context,
        'ส่งคำขอถอนเงินเรียบร้อยแล้ว รอแอดมินอนุมัติ',
      );
      _amountCtrl.clear();
      _fetchWalletData();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final fee = withdrawAmount * 0.05;
    final netAmount = (withdrawAmount - fee).clamp(0, double.infinity);
    final bankName = _shop['bank_name'] ?? 'กสิกรไทย';
    final bankAccNum = _shop['bank_account_number'] ?? '123-4-56789-0';
    final bankAccName = _shop['bank_account_name'] ?? 'ชื่อบัญชีร้านค้า';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Wallet ของร้าน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWalletData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Card (Matches 3.4_Owner_Wallet.png)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F3B7A), Color(0xFF1D5FB4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF103B7B)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เครดิตร้านคงเหลือ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _balance.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'เครดิต',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'รอโอนจากการจองที่ยังไม่เสร็จสิ้น ${_pendingBalance.toStringAsFixed(0)} เครดิต',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Withdrawal Form Card (Matches 3.4_Owner_Wallet.png)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ขอถอนเงินเข้าบัญชีร้าน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Amount input box with suffix 'เครดิต'
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _amountCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '0',
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const Text(
                                  'เครดิต',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Fee breakdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ค่าธรรมเนียมแพลตฟอร์ม 5%',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '- ฿${fee.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ยอดที่จะได้รับ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '฿${netAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Bank details row
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$bankName • $bankAccNum • $bankAccName',
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
                          const SizedBox(height: 16),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSubmitting ? null : _handleWithdraw,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'ส่งคำขอถอนเงิน',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transaction History Section (Matches 3.4_Owner_Wallet.png)
                    const Text(
                      'ประวัติเครดิตร้าน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'ยังไม่มีประวัติเครดิต',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._transactions.map((t) => _buildTransactionCard(t)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTransactionCard(dynamic t) {
    final type = t['type'] ?? 'booking_income';
    final amount = double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
    final isPositive = amount >= 0 && type != 'withdrawal';
    final desc = t['description'] ?? 'บริการเสร็จสิ้น';
    final createdAt = t['created_at']?.toString().substring(0, 10) ?? '';

    Color iconBg = isPositive
        ? const Color(0xFFF6FFED)
        : const Color(0xFFFFF2F0);
    Color iconColor = isPositive
        ? const Color(0xFF52C41A)
        : const Color(0xFFF5222D);
    IconData icon = isPositive
        ? Icons.check_circle_outline
        : Icons.arrow_upward;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  createdAt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? const Color(0xFF52C41A)
                  : const Color(0xFFF5222D),
            ),
          ),
        ],
      ),
    );
  }
}
