import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import 'review_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(100, 38),
            ),
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
      AppSnackBar.showSuccess(context, 'ยกเลิกคิวสำเร็จ และคืนเครดิตเข้ากระเป๋าเรียบร้อยแล้ว');
      bookingProvider.fetchMyBookings();
    } else {
      AppSnackBar.showError(context, bookingProvider.errorMessage ?? 'ยกเลิกไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final all = bookingProvider.bookings;

    // "กำลังจะถึง": pending_service, checked_in, in_service
    final upcoming = all.where((b) => b.status == 'pending_service' || b.status == 'checked_in' || b.status == 'in_service').toList();
    // "ประวัติ": completed, cancelled, no_show
    final history = all.where((b) => b.status == 'completed' || b.status.startsWith('cancelled') || b.status == 'no_show').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('การจองของฉัน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'กำลังจะถึง (${upcoming.length})'),
                  Tab(text: 'ประวัติ (${history.length})'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: bookingProvider.isLoading && all.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => bookingProvider.fetchMyBookings(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(upcoming, isUpcoming: true),
                  _buildBookingsList(history, isUpcoming: false),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUpcoming ? Icons.calendar_today_outlined : Icons.history, size: 54, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              isUpcoming ? 'ไม่มีรายการจองที่กำลังจะถึง' : 'ไม่มีประวัติการจอง',
              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildBookingCard(list[i]),
    );
  }

  Widget _buildBookingCard(BookingModel b) {
    final dateStr = b.bookingDate;
    final startTime = b.startTime.length >= 5 ? b.startTime.substring(0, 5) : b.startTime;
    final endTime = b.endTime.length >= 5 ? b.endTime.substring(0, 5) : b.endTime;

    final isInProgress = b.status == 'in_service' || b.status == 'checked_in';
    final isUpcoming = b.status == 'pending_service';
    final isCompleted = b.status == 'completed';

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
          // Header: Shop Name & Status Badge (Matches 2.7_BookingManage.png)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  b.shopName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isInProgress
                      ? const Color(0xFFFFF7E6)
                      : isUpcoming
                          ? const Color(0xFFE6F4FF)
                          : isCompleted
                              ? const Color(0xFFF6FFED)
                              : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  b.statusThai,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInProgress
                        ? const Color(0xFFD46B08)
                        : isUpcoming
                            ? AppTheme.primaryColor
                            : isCompleted
                                ? const Color(0xFF389E0D)
                                : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('$dateStr • $startTime–$endTime น.', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),

          // Vehicle & Service
          Row(
            children: [
              const Icon(Icons.directions_car_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('${b.plateNumber} • ${b.serviceName}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          // Price & Escrow Hold line (Matches 2.7_BookingManage.png)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ชำระแล้ว (พักไว้ในระบบ)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text('${b.finalPrice.toStringAsFixed(0)} เครดิต', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13)),
              ],
            ),
          ),

          // Case 1: In Progress Live Stepper (Matches 2.7_BookingManage.png)
          if (isInProgress) ...[
            const SizedBox(height: 16),
            _buildLiveStepper(),
          ],

          // Case 2: Confirmed with 24-hr refund warning & Cancel Button
          if (b.canCancel) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FFED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7EB8F)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF389E0D)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ยกเลิกล่วงหน้าอย่างน้อย 24 ชม. รับเครดิตคืนเต็มจำนวน หลังจากนั้นหรือไม่มาตามนัด จะไม่ได้รับเครดิตคืน',
                      style: TextStyle(fontSize: 11, color: Color(0xFF274916), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF2F0),
                foregroundColor: const Color(0xFFCF1322),
                elevation: 0,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _handleCancelBooking(b),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('ยกเลิกการจอง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],

          // Case 3: Completed with Review Button (Matches 2.6_Review.png)
          if (b.canReview) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6F4FF),
                foregroundColor: AppTheme.primaryColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      bookingId: b.id,
                      shopName: b.shopName,
                      serviceName: b.serviceName,
                      bookingDate: dateStr,
                    ),
                  ),
                ).then((_) => Provider.of<BookingProvider>(context, listen: false).fetchMyBookings());
              },
              icon: const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
              label: const Text('ให้คะแนนรีวิวร้านค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveStepper() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepNode(done: true, active: false),
            _buildStepLine(done: true),
            _buildStepNode(done: true, active: false),
            _buildStepLine(done: true),
            _buildStepNode(done: false, active: true),
            _buildStepLine(done: false),
            _buildStepNode(done: false, active: false),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('ยืนยัน', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('เข้ารับบริการ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('กำลังให้บริการ', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            Text('เสร็จสิ้น', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepNode({required bool done, required bool active}) {
    if (active) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 6),
          ],
        ),
        child: const Icon(Icons.local_car_wash, size: 12, color: Colors.white),
      );
    }
    if (done) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepLine({required bool done}) {
    return Expanded(
      child: Container(
        height: 3,
        color: done ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }
}
