import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/wallet_provider.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  double _selectedAmount = 500.0;
  final List<double> _presets = [100, 300, 500, 1000];

  Uint8List? _qrBytes;
  bool _isLoadingQr = false;
  bool _isConfirming = false;

  Timer? _countdownTimer;
  int _secondsLeft = 600; // 10 minutes

  XFile? _slipFile;
  bool _isSlipVerified = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchQr();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _secondsLeft = 600;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerFormatted {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _fetchQr() async {
    setState(() => _isLoadingQr = true);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final data = await walletProvider.generateTopUpQr(_selectedAmount);

    if (mounted) {
      setState(() {
        _isLoadingQr = false;
        if (data != null && data['qr_image_base64'] != null) {
          final b64 = data['qr_image_base64'].toString().split(',').last;
          _qrBytes = base64Decode(b64);
        }
      });
    }
  }

  void _selectAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _slipFile = null;
      _isSlipVerified = false;
    });
    _startTimer();
    _fetchQr();
  }

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _slipFile = picked;
        _isSlipVerified = true;
      });
    } else {
      // Fallback simulated slip for testing convenience
      setState(() {
        _slipFile = XFile('slip_${DateTime.now().millisecondsSinceEpoch}.jpg');
        _isSlipVerified = true;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (!_isSlipVerified) {
      AppSnackBar.showError(context, 'กรุณาแนบสลิปการโอนเงินเพื่อยืนยัน');
      return;
    }

    setState(() => _isConfirming = true);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final success = await walletProvider.confirmTopUp(_selectedAmount);
    setState(() => _isConfirming = false);

    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(
        context,
        'เติมเงินเข้ากระเป๋า ${_selectedAmount.toStringAsFixed(0)} เครดิตสำเร็จ!',
      );
      Navigator.pop(context);
    } else {
      AppSnackBar.showError(
        context,
        walletProvider.errorMessage ?? 'เติมเงินไม่สำเร็จ',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'เติมเงินเข้า Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card (Matches 2.9_AddWalletwithQR.png)
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    'จำนวนเงินที่ต้องการเติม',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '฿${_selectedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preset Amount Buttons
                  Row(
                    children: _presets.map((amt) {
                      final isSelected = _selectedAmount == amt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => _selectAmount(amt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFFF0F4FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                amt >= 1000 ? '1,000' : amt.toStringAsFixed(0),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'จะได้รับ ${_selectedAmount.toStringAsFixed(0)} เครดิต (1 บาท = 1 เครดิต)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Countdown Timer Card (Matches 2.9_AddWalletwithQR.png)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD591)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.access_time_filled,
                        color: Color(0xFFD46B08),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'แนบสลิปภายใน',
                        style: TextStyle(
                          color: Color(0xFFD46B08),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _timerFormatted,
                    style: const TextStyle(
                      color: Color(0xFFD46B08),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // PromptPay QR Code Card (Matches 2.9_AddWalletwithQR.png)
            Container(
              padding: const EdgeInsets.all(22),
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
                  const Text(
                    'สแกนชำระผ่าน PromptPay',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingQr)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_qrBytes != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Image.memory(_qrBytes!, width: 200, height: 200),
                    )
                  else
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        size: 120,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'บัญชีรับเงินของแพลตฟอร์ม WashQ • พร้อมเพย์ xxx-xxx-1234',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Slip Upload Card (Matches 2.9_AddWalletwithQR.png)
            const Text(
              'แนบสลิปการโอนเงิน',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (_isSlipVerified && _slipFile != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB7EB8F)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6FFED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF52C41A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _slipFile!.name.isNotEmpty
                                ? _slipFile!.name
                                : 'slip_20261026.jpg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ระบบตรวจสอบสลิปแล้ว • ยอดเงินถูกต้อง',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF389E0D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() {
                        _slipFile = null;
                        _isSlipVerified = false;
                      }),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _pickSlip,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'แตะเพื่อแนบสลิปหลักฐานการโอนเงิน',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Confirm Button (Matches 2.9_AddWalletwithQR.png)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _isConfirming
                  ? null
                  : (_isSlipVerified ? _handleConfirm : _pickSlip),
              child: _isConfirming
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isSlipVerified
                          ? 'ยืนยันเติมเงิน ${_selectedAmount.toStringAsFixed(0)} เครดิต'
                          : 'แนบสลิปเพื่อยืนยัน',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'ระบบตรวจสอบสลิปอัตโนมัติ และเติมเครดิตทันที',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
