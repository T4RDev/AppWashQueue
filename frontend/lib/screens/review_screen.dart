import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;
  final String shopName;
  final String serviceName;
  final String bookingDate;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.shopName,
    required this.serviceName,
    required this.bookingDate,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ApiService _api = ApiService();
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 5:
        return 'ยอดเยี่ยม • 5 จาก 5 คะแนน';
      case 4:
        return 'ดีมาก • 4 จาก 5 คะแนน';
      case 3:
        return 'ปานกลาง • 3 จาก 5 คะแนน';
      case 2:
        return 'พอใช้ • 2 จาก 5 คะแนน';
      case 1:
        return 'ควรปรับปรุง • 1 จาก 5 คะแนน';
      default:
        return '$_rating จาก 5 คะแนน';
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    final res = await _api.post(
      ApiConstants.reviews,
      body: {
        'booking_id': widget.bookingId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
      },
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(
        context,
        'ส่งคะแนนรีวิวสำเร็จ ขอบคุณสำหรับข้อเสนอแนะ! ⭐',
      );
      Navigator.pop(context, true);
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'ให้คะแนนร้าน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Shop Avatar (Matches 2.6_Review.png)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Shop Name & Service (Matches 2.6_Review.png)
            Text(
              widget.shopName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'ใช้บริการเมื่อ ${widget.bookingDate} • ${widget.serviceName}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Status Chip: ✓ บริการเสร็จสิ้น
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FFED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB7EB8F)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check, size: 16, color: Color(0xFF389E0D)),
                  SizedBox(width: 4),
                  Text(
                    'บริการเสร็จสิ้น',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF389E0D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Satisfaction Card (Matches 2.6_Review.png)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'คุณพอใจกับบริการแค่ไหน?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5 Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starVal),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Icon(
                            Icons.star_rounded,
                            size: 44,
                            color: starVal <= _rating
                                ? const Color(0xFFFFB800)
                                : Colors.grey.shade200,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _ratingLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'เขียนความคิดเห็นเพิ่มเติม (ถ้ามี)...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PDPA / Limit Note (Matches 2.6_Review.png)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ให้คะแนนได้ 1 ครั้งต่อการจอง เฉพาะการจองที่บริการเสร็จสิ้นแล้ว',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
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
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'ส่งคะแนน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
