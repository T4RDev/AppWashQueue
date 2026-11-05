import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../core/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();
    });
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เติมเงินเข้า Wallet 💳'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ระบุจำนวนเงินที่ต้องการเติม (บาท):', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '฿ ',
                hintText: '100 - 5,000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;

              Navigator.pop(ctx);
              final walletProvider = Provider.of<WalletProvider>(context, listen: false);
              final qrData = await walletProvider.generateTopUpQr(amount);

              if (qrData != null && mounted) {
                _showPromptPayModal(amount, qrData['qr_code_image']);
              }
            },
            child: const Text('สร้าง QR Code'),
          ),
        ],
      ),
    );
  }

  void _showPromptPayModal(double amount, String qrDataUrl) {
    // แยก base64 image จาก data:image/png;base64,...
    final base64String = qrDataUrl.split(',').last;
    final imageBytes = base64Decode(base64String);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('สแกนจ่ายผ่าน PromptPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ยอดชำระ: ฿${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Image.memory(imageBytes, width: 220, height: 220),
            ),
            const SizedBox(height: 16),
            const Text(
              'เปิดแอปพลิเคชันธนาคารของคุณ และสแกน QR Code เพื่อชำระเงิน',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                final success = await walletProvider.confirmTopUp(amount);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เติมเงินเข้ากระเป๋าสำเร็จเรียบร้อยแล้ว! 💸'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('จำลองการชำระเงินสำเร็จ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final bankNameController = TextEditingController();
    final accNameController = TextEditingController();
    final accNumController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ถอนเงินเข้าบัญชีธนาคาร 🏦'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(labelText: 'ชื่อธนาคาร (เช่น กสิกรไทย, ไทยพาณิชย์)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accNameController,
                decoration: const InputDecoration(labelText: 'ชื่อบัญชี'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accNumController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'เลขที่บัญชี'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;

              Navigator.of(ctx).pop();

              final walletProvider = Provider.of<WalletProvider>(context, listen: false);
              final success = await walletProvider.requestWithdrawal(
                amount: amount,
                bankName: bankNameController.text.trim(),
                bankAccountName: accNameController.text.trim(),
                bankAccountNumber: accNumController.text.trim(),
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ส่งคำขอถอนเงินสำเร็จ กรุณารอแอดมินดำเนินการโอน'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(walletProvider.errorMessage ?? 'ถอนเงินไม่สำเร็จ'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('ส่งคำขอถอนเงิน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final wallet = walletProvider.wallet;

    return Scaffold(
      appBar: AppBar(title: const Text('กระเป๋าเงิน (Wallet)')),
      body: RefreshIndicator(
        onRefresh: () async => walletProvider.fetchMyWallet(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ยอดเงินคงเหลือ (Available Balance)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '฿${(wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if ((wallet?.pendingBalance ?? 0.0) > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'รอดำเนินการ (Escrow): ฿${wallet!.pendingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Buttons: Top-up & Withdraw
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('เติมเงิน QR'),
                            onPressed: _showTopUpDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            label: const Text('ถอนเงิน'),
                            onPressed: _showWithdrawDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transaction History
              const Text(
                'ประวัติธุรกรรมล่าสุด 📜',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),

              if (wallet == null || wallet.transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('ยังไม่มีประวัติธุรกรรม', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: wallet.transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final tx = wallet.transactions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: tx.isPositive ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(
                          tx.isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                          color: tx.isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(tx.typeThai, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(tx.notes ?? tx.createdAt, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      trailing: Text(
                        '${tx.isPositive ? '+' : '-'}฿${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tx.isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

