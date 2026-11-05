import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../core/app_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCancelBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการยกเลิกคิว'),
        content: const Text(
          'คุณต้องการยกเลิกคิวนี้ใช่หรือไม่?\n\n* หากยกเลิกล่วงหน้าอย่างน้อย 24 ชั่วโมง คุณจะได้รับเครดิตคืนเข้า Wallet เต็มจำนวนทันที',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ปิด')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยืนยันยกเลิก'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final success = await bookingProvider.cancelBooking(booking.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยกเลิกคิวสำเร็จ และคืนเงินเข้ากระเป๋าเรียบร้อยแล้ว'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? 'ยกเลิกไม่สำเร็จ'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showReviewDialog(BookingModel booking) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('ให้คะแนน ${booking.shopName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ความพึงพอใจในการให้บริการ'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setDialogState(() => rating = starIndex),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'เขียนรีวิวหรือข้อเสนอแนะ (ไม่บังคับ)...',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
                  final success = await bookingProvider.submitReview(
                    booking.id,
                    rating,
                    commentController.text.trim().isNotEmpty ? commentController.text.trim() : null,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ขอบคุณสำหรับการรีวิว! ⭐'), backgroundColor: AppTheme.success),
                    );
                  }
                },
                child: const Text('ส่งรีวิว'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('การจองของฉัน 📋'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'รอรับบริการ'),
            Tab(text: 'เสร็จสิ้น'),
            Tab(text: 'ยกเลิก'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => bookingProvider.fetchMyBookings(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingList(bookingProvider.bookings),
            _buildBookingList(
              bookingProvider.bookings.where((b) => b.status == 'pending_service' || b.status == 'in_service' || b.status == 'checked_in').toList(),
            ),
            _buildBookingList(
              bookingProvider.bookings.where((b) => b.status == 'completed').toList(),
            ),
            _buildBookingList(
              bookingProvider.bookings.where((b) => b.status.startsWith('cancelled') || b.status == 'no_show').toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text('ไม่มีรายการจองในหมวดนี้', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      b.bookingCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    _buildStatusBadge(b.status, b.statusThai),
                  ],
                ),
                const Divider(height: 20),

                // Shop & Service
                Text(
                  b.shopName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                Text('บริการ: ${b.serviceName}', style: const TextStyle(fontSize: 14)),
                Text('รถ: ${b.plateNumber} (${b.brand} ${b.model})', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),

                // Date & Time Slot
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      '${b.bookingDate} | เวลา ${b.startTime.substring(0, 5)} - ${b.endTime.substring(0, 5)} น.',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.accentColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดชำระสุทธิ:'),
                    Text(
                      '฿${b.finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    ),
                  ],
                ),

                // Actions (Cancel or Review)
                if (b.canCancel || b.canReview) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (b.canCancel)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            minimumSize: const Size(110, 36),
                          ),
                          onPressed: () => _handleCancelBooking(b),
                          child: const Text('ยกเลิกคิว (ได้เงินคืน)', style: TextStyle(fontSize: 12)),
                        ),
                      if (b.canReview)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            minimumSize: const Size(120, 36),
                          ),
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text('ให้คะแนนรีวิว', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showReviewDialog(b),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color bg;
    Color text;

    switch (status) {
      case 'pending_service':
        bg = AppTheme.primaryLight;
        text = AppTheme.primaryColor;
        break;
      case 'in_service':
      case 'checked_in':
        bg = Colors.amber.shade100;
        text = Colors.brown;
        break;
      case 'completed':
        bg = Colors.green.shade100;
        text = Colors.green.shade800;
        break;
      default:
        bg = Colors.red.shade100;
        text = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

