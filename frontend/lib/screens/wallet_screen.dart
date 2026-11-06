import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../models/wallet_model.dart';
import '../core/app_theme.dart';
import 'top_up_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _selectedFilter = 'all'; // 'all', 'topup', 'payment', 'refund'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();
    });
  }

  List<WalletTransactionModel> _filterTransactions(
    List<WalletTransactionModel> list,
  ) {
    if (_selectedFilter == 'all') return list;
    if (_selectedFilter == 'topup') {
      return list.where((t) => t.type == 'topup').toList();
    }
    if (_selectedFilter == 'payment') {
      return list
          .where((t) => t.type == 'booking_payment' || t.type == 'payment')
          .toList();
    }
    if (_selectedFilter == 'refund') {
      return list.where((t) => t.type == 'refund').toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final wallet = walletProvider.wallet;
    final allTransactions = wallet?.transactions ?? [];
    final transactions = _filterTransactions(allTransactions);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Wallet ของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '1 เครดิต = 1 บาท',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => walletProvider.fetchMyWallet(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card (Matches 2.8_MyWallet.png)
              Container(
                width: double.infinity,
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
                      color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'เครดิตคงเหลือ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          (wallet?.balance ?? 0.0).toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'เครดิต',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Escrow Pending Hold notice
                    if ((wallet?.pendingBalance ?? 0.0) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'หักไว้ ${wallet!.pendingBalance.toStringAsFixed(0)} เครดิต (การจองที่รอดำเนินการ)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 4),

                    const SizedBox(height: 18),

                    // Top-up Button ONLY (Member cannot withdraw cash!)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TopUpScreen(),
                          ),
                        ).then((_) => walletProvider.fetchMyWallet());
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      label: const Text(
                        'เติมเงิน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transaction History Section (Matches 2.8_MyWallet.png)
              const Text(
                'ประวัติธุรกรรม',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips: [ทั้งหมด] [เติม] [ใช้] [คืน]
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'ทั้งหมด'),
                    const SizedBox(width: 8),
                    _buildFilterChip('topup', 'เติม'),
                    const SizedBox(width: 8),
                    _buildFilterChip('payment', 'ใช้'),
                    const SizedBox(width: 8),
                    _buildFilterChip('refund', 'คืน'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Transactions List
              if (walletProvider.isLoading && allTransactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ยังไม่มีรายการธุรกรรมในหมวดนี้',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (ctx, i) =>
                      _buildTransactionCard(transactions[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFE6F4FF),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel t) {
    final isPositive = t.isPositive;
    final date = t.createdAt.length >= 10
        ? t.createdAt.substring(0, 10)
        : t.createdAt;

    Color iconBg;
    Color iconColor;
    IconData icon;
    String statusText;
    Color statusBg;
    Color statusColor;

    if (t.type == 'topup') {
      iconBg = const Color(0xFFF6FFED);
      iconColor = const Color(0xFF52C41A);
      icon = Icons.arrow_downward;
      statusText = 'สำเร็จ';
      statusBg = const Color(0xFFF6FFED);
      statusColor = const Color(0xFF52C41A);
    } else if (t.type == 'refund') {
      iconBg = const Color(0xFFE6F4FF);
      iconColor = AppTheme.primaryColor;
      icon = Icons.refresh;
      statusText = 'คืนแล้ว';
      statusBg = const Color(0xFFE6F4FF);
      statusColor = AppTheme.primaryColor;
    } else {
      // Payment or Hold
      iconBg = const Color(0xFFFFF7E6);
      iconColor = const Color(0xFFD46B08);
      icon = Icons.lock_outline;
      statusText = t.status == 'held' ? 'หักไว้' : 'ชำระแล้ว';
      statusBg = const Color(0xFFFFF7E6);
      statusColor = const Color(0xFFD46B08);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  t.notes ?? t.typeThai,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}${t.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPositive
                      ? const Color(0xFF52C41A)
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
