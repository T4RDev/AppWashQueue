import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../providers/wallet_provider.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import 'top_up_screen.dart';

class PayCreditScreen extends StatefulWidget {
  final int shopId;
  final String shopName;
  final String shopAddress;
  final int vehicleId;
  final String vehiclePlate;
  final String vehicleType;
  final int serviceId;
  final String serviceName;
  final double servicePrice;
  final int timeSlotId;
  final String bookingDate;
  final String slotTimeRange;
  final String? discountCode;

  const PayCreditScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.timeSlotId,
    required this.bookingDate,
    required this.slotTimeRange,
    this.discountCode,
  });

  @override
  State<PayCreditScreen> createState() => _PayCreditScreenState();
}

class _PayCreditScreenState extends State<PayCreditScreen> {
  Timer? _countdownTimer;
  int _secondsLeft = 300; // 5 minutes (Matches 2.4_Pay_Credit.png)
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        if (mounted) {
          AppSnackBar.showError(
            context,
            'หมดเวลาทำรายการ ระบบยกเลิกการจองอัตโนมัติ',
          );
          Navigator.pop(context);
        }
      }
    });
  }

  String get _timerFormatted {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handlePayment() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final balance = walletProvider.wallet?.balance ?? 0.0;

    if (balance < widget.servicePrice) {
      AppSnackBar.showError(
        context,
        'เครดิตไม่เพียงพอ กรุณาเติมเงินเข้า Wallet',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TopUpScreen()),
      ).then((_) => walletProvider.fetchMyWallet());
      return;
    }

    setState(() => _isPaying = true);

    final result = await bookingProvider.createBooking(
      shopId: widget.shopId,
      vehicleId: widget.vehicleId,
      serviceId: widget.serviceId,
      timeSlotId: widget.timeSlotId,
      bookingDate: widget.bookingDate,
      discountCode: widget.discountCode,
    );

    setState(() => _isPaying = false);

    if (!mounted) return;
    if (result != null) {
      AppSnackBar.showSuccess(
        context,
        'จองคิวและชำระเครดิตสำเร็จเรียบร้อย! 🚗✨',
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      AppSnackBar.showError(
        context,
        bookingProvider.errorMessage ?? 'การชำระเงินไม่สำเร็จ',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final balance = walletProvider.wallet?.balance ?? 0.0;
    final price = widget.servicePrice;
    final balanceAfter = balance - price;
    final isEnough = balance >= price;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'ชำระด้วยเครดิต',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Orange/Red Gradient Countdown Banner (Matches 2.4_Pay_Credit.png)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E36), Color(0xFFFFAE33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E36).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เหลือเวลาชำระเครดิต',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timerFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'หากไม่ชำระภายใน 5 นาที ระบบจะยกเลิกการจองอัตโนมัติ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shop & Booking Details Card (Matches 2.4_Pay_Credit.png)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.shopName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.shopAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'รอชำระ',
                          style: TextStyle(
                            color: Color(0xFFD46B08),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _buildDetailRow(
                    'รถ',
                    '${widget.vehiclePlate} • ${widget.vehicleType}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('บริการ', widget.serviceName),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'วัน / สล็อต',
                    '${widget.bookingDate} • ${widget.slotTimeRange} น.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Calculation Card (Matches 2.4_Pay_Credit.png)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'เครดิตคงเหลือ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${balance.toStringAsFixed(0)} เครดิต',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ค่าบริการ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '- ${price.toStringAsFixed(0)} เครดิต',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'คงเหลือหลังชำระ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${balanceAfter.toStringAsFixed(0)} เครดิต',
                        style: TextStyle(
                          color: isEnough
                              ? AppTheme.primaryColor
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Escrow Protection Note (Matches 2.4_Pay_Credit.png)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E4FF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.shield_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ระบบจะพักเครดิตไว้จนกว่าบริการจะเสร็จสิ้น จึงโอนให้ร้าน ยกเลิกล่วงหน้าอย่างน้อย 24 ชม. รับเครดิตคืนเต็มจำนวน',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D39C4),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pay Button (Matches 2.4_Pay_Credit.png)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnough
                    ? AppTheme.primaryColor
                    : Colors.orangeAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _isPaying ? null : _handlePayment,
              child: _isPaying
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEnough
                              ? 'ชำระ ${price.toStringAsFixed(0)} เครดิต'
                              : 'เครดิตไม่พอ • เติมเงินเพื่อชำระ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopUpScreen()),
                  ).then((_) => walletProvider.fetchMyWallet());
                },
                child: const Text(
                  'เครดิตไม่พอ? เติมเงินเข้า Wallet',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
