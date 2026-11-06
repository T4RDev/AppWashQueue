import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/shop_model.dart';
import '../models/vehicle_model.dart';
import '../providers/shop_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/wallet_provider.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import 'wallet_screen.dart';
import 'my_cars_screen.dart';
import 'pay_credit_screen.dart';

class BookingScreen extends StatefulWidget {
  final ShopModel shop;
  final String? initialVehicleType;
  final String? initialServiceName;

  const BookingScreen({
    super.key,
    required this.shop,
    this.initialVehicleType,
    this.initialServiceName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  VehicleModel? _selectedVehicle;
  ServiceModel? _selectedService;
  TimeSlotModel? _selectedSlot;
  late DateTime _selectedDate;
  late List<DateTime> _availableDates;

  final _discountController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow (min 1 day advance booking per mockup 2.3_Booking.png)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    // Generate 7 consecutive days starting from tomorrow
    _availableDates = List.generate(7, (i) {
      final d = tomorrow.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vProvider = Provider.of<VehicleProvider>(context, listen: false);
      await vProvider.fetchMyVehicles();
      Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();

      if (mounted) {
        // 1. Prioritize matching vehicle type or pick first vehicle
        if (vProvider.vehicles.isNotEmpty) {
          VehicleModel? matched;
          if (widget.initialVehicleType != null) {
            try {
              matched = vProvider.vehicles.firstWhere(
                (v) => v.vehicleType == widget.initialVehicleType,
              );
            } catch (_) {}
          }
          matched ??= vProvider.vehicles.first;
          setState(() => _selectedVehicle = matched);
        }

        // 2. Prioritize matching service name or pick first service
        if (widget.shop.services.isNotEmpty) {
          ServiceModel? matchedService;
          if (widget.initialServiceName != null) {
            try {
              matchedService = widget.shop.services.firstWhere(
                (s) =>
                    s.name.contains(widget.initialServiceName!) ||
                    widget.initialServiceName!.contains(s.name),
              );
            } catch (_) {}
          }
          matchedService ??= widget.shop.services.first;
          setState(() => _selectedService = matchedService);
        }

        _fetchSlots();
      }
    });
  }

  void _fetchSlots() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    Provider.of<ShopProvider>(context, listen: false).fetchAvailableSlots(
      widget.shop.id,
      dateStr,
      vehicleType: _selectedVehicle?.vehicleType,
    );
    setState(() => _selectedSlot = null);
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _discountController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final price = _selectedService?.price ?? 150.0;
    if (code == 'WASH10' || code == 'DISCOUNT10') {
      setState(() {
        _appliedCoupon = code;
        _discountAmount = (price * 0.1).roundToDouble();
      });
      AppSnackBar.showSuccess(context, 'ใช้โค้ดส่วนลด 10% เรียบร้อยแล้ว');
    } else if (code == 'NEW50' || code == 'WASH50') {
      setState(() {
        _appliedCoupon = code;
        _discountAmount = 50.0 > price ? price : 50.0;
      });
      AppSnackBar.showSuccess(context, 'ใช้โค้ดส่วนลด ฿50 เรียบร้อยแล้ว');
    } else if (code == 'SAVE20') {
      setState(() {
        _appliedCoupon = code;
        _discountAmount = 20.0 > price ? price : 20.0;
      });
      AppSnackBar.showSuccess(context, 'ใช้โค้ดส่วนลด ฿20 เรียบร้อยแล้ว');
    } else {
      setState(() {
        _appliedCoupon = code;
        _discountAmount = 30.0 > price ? price : 30.0;
      });
      AppSnackBar.showSuccess(
        context,
        'ใช้โค้ดส่วนลด $code สำเร็จ (ลด ฿${_discountAmount.toStringAsFixed(0)})',
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _discountController.clear();
    });
    AppSnackBar.showInfo(context, 'ยกเลิกโค้ดส่วนลดแล้ว');
  }

  double get _finalPrice {
    final basePrice = _selectedService?.price ?? 150.0;
    final finalP = basePrice - _discountAmount;
    return finalP < 0 ? 0 : finalP;
  }

  Future<void> _handleConfirmBooking() async {
    if (_selectedVehicle == null) {
      AppSnackBar.showError(context, 'กรุณาเลือกรถที่จะเข้ารับบริการ');
      return;
    }

    if (_selectedService == null) {
      AppSnackBar.showError(context, 'กรุณาเลือกบริการที่ต้องการ');
      return;
    }

    if (_selectedSlot == null) {
      AppSnackBar.showError(context, 'กรุณาเลือกสล็อตเวลาให้บริการ');
      return;
    }

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final currentBalance = walletProvider.wallet?.balance ?? 0.0;
    final priceToPay = _finalPrice;

    // Check Wallet balance
    if (currentBalance < priceToPay) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('ยอดเงินใน Wallet ไม่เพียงพอ', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'ค่าบริการ ฿${priceToPay.toStringAsFixed(0)} เครดิต แต่คุณมี ฿${currentBalance.toStringAsFixed(0)} เครดิต\nต้องการเติมเงินก่อนหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              child: const Text('ไปเติมเงิน'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to PayCreditScreen (Matches 2.4_Pay_Credit.png)
    final slotTime =
        '${_selectedSlot!.startTime.substring(0, 5)}–${_selectedSlot!.endTime.substring(0, 5)}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayCreditScreen(
          shopId: widget.shop.id,
          shopName: widget.shop.shopName,
          shopAddress: widget.shop.address,
          vehicleId: _selectedVehicle!.id,
          vehiclePlate: _selectedVehicle!.plateNumber,
          vehicleType: _selectedVehicle!.vehicleTypeThai,
          serviceId: _selectedService!.id,
          serviceName: _selectedService!.name,
          servicePrice: priceToPay,
          timeSlotId: _selectedSlot!.id,
          bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          slotTimeRange: slotTime,
          discountCode: _appliedCoupon,
        ),
      ),
    );
  }

  String _getThaiMonthYear(DateTime date) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    final monthName = months[date.month - 1];
    final beYear = date.year + 543;
    return '$monthName $beYear';
  }

  String _getThaiDayInitial(int weekday) {
    const days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    return days[weekday - 1];
  }

  String _getThaiShortMonth(int month) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return months[month - 1];
  }

  String _formatBookingDateTimeThai() {
    final dayInit = _getThaiDayInitial(_selectedDate.weekday);
    final dayNum = _selectedDate.day;
    final shortMonth = _getThaiShortMonth(_selectedDate.month);
    final shortBeYear = (_selectedDate.year + 543).toString().substring(2);
    final slotStr = _selectedSlot != null
        ? '${_selectedSlot!.startTime.substring(0, 5)}–${_selectedSlot!.endTime.substring(0, 5)}'
        : 'ยังไม่เลือกเวลา';
    return '$dayInit $dayNum $shortMonth $shortBeYear • $slotStr';
  }

  IconData _getVehicleIcon(String? vehicleType) {
    final type = vehicleType?.toLowerCase() ?? '';
    if (type.contains('motorcycle') || type.contains('มอเตอร์ไซค์')) {
      return Icons.two_wheeler_rounded;
    }
    if (type.contains('suv')) {
      return Icons.directions_car_filled_rounded;
    }
    return Icons.directions_car_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final balance = walletProvider.wallet?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'จองคิวล้างรถ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. เลือกรถของคุณ (Matches 2.3_Booking.png)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เลือกรถของคุณ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCarsScreen()),
                    );
                    if (mounted) {
                      final vp = Provider.of<VehicleProvider>(context, listen: false);
                      await vp.fetchMyVehicles();
                      if (vp.vehicles.isNotEmpty && _selectedVehicle == null) {
                        setState(() => _selectedVehicle = vp.vehicles.first);
                        _fetchSlots();
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      '+ เพิ่มรถ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (vehicleProvider.vehicles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'คุณยังไม่มีข้อมูลรถที่บันทึกไว้',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCarsScreen()),
                        );
                        if (mounted) {
                          final vp = Provider.of<VehicleProvider>(context, listen: false);
                          await vp.fetchMyVehicles();
                          if (vp.vehicles.isNotEmpty) {
                            setState(() => _selectedVehicle = vp.vehicles.first);
                            _fetchSlots();
                          }
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('เพิ่มรถเลย'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: vehicleProvider.vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final v = vehicleProvider.vehicles[i];
                    final isSelected = _selectedVehicle?.id == v.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedVehicle = v);
                        _fetchSlots();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 215,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.015),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _getVehicleIcon(v.vehicleType),
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        v.plateNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${v.vehicleTypeThai} • ${v.brand} ${v.model}'.trim(),
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
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0066FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 22),

            // 2. เลือกวันที่ (Matches 2.3_Booking.png)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'เลือกวันที่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '* ต้องจองล่วงหน้าอย่างน้อย 1 วัน',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD46B08),
                      ),
                    ),
                  ],
                ),
                Text(
                  _getThaiMonthYear(_selectedDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date horizontal cards
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableDates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final date = _availableDates[i];
                  final isSelected =
                      _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _fetchSlots();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getThaiDayInitial(date.weekday),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // 3. เลือกสล็อตเวลา (Matches 2.3_Booking.png)
            const Text(
              'เลือกสล็อตเวลา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (shopProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (shopProvider.availableSlots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ไม่มีสล็อตเวลาว่างในวันนี้ หรือร้านปิดทำการ',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: shopProvider.availableSlots.map((slot) {
                      final isSelected = _selectedSlot?.id == slot.id;
                      final isAvailable = slot.isAvailable;
                      final isFull = !isAvailable || slot.availableCount <= 0;

                      final timeLabel =
                          '${slot.startTime.substring(0, 5)} – ${slot.endTime.substring(0, 5)}';

                      return GestureDetector(
                        onTap: isFull
                            ? null
                            : () {
                                setState(() => _selectedSlot = slot);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: cardWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isFull ? const Color(0xFFF8FAFC) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0066FF)
                                  : isFull
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.015),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 15,
                                    color: isFull
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF52C41A),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      timeLabel,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isFull ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isFull ? 'เต็มแล้ว' : 'ว่าง ${slot.availableCount} คิว',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isFull ? const Color(0xFFEF4444) : const Color(0xFF52C41A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 22),

            // 4. ส่วนลดคูปอง (Discount Coupon - User Requested)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                            color: Color(0xFF0066FF),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'คูปองส่วนลด',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (_appliedCoupon != null)
                        InkWell(
                          onTap: _removeCoupon,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'ลบโค้ด $_appliedCoupon',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFF5222D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Color(0xFFF5222D),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _discountController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'กรอกโค้ดส่วนลด (เช่น WASH10, NEW50)',
                              hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(80, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ใช้โค้ด',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (_appliedCoupon != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF52C41A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ใช้ส่วนลดสำเร็จ ลด ฿${_discountAmount.toStringAsFixed(0)} เครดิต',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52C41A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 5. สรุปการจอง (Matches 2.3_Booking.png)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                    'สรุปการจอง',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // บริการ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'บริการ (${_selectedVehicle?.vehicleTypeThai ?? 'รถยนต์'})',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _selectedService?.name ?? 'ล้างอัดฉีด',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // วัน / เวลา
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'วัน / เวลา',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _formatBookingDateTimeThai(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  if (_appliedCoupon != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ส่วนลดคูปอง ($_appliedCoupon)',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF52C41A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '-${_discountAmount.toStringAsFixed(0)} เครดิต',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52C41A),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                  // ยอดชำระ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'ยอดชำระ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_finalPrice.toStringAsFixed(0)} เครดิต',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // เครดิตคงเหลือใน Wallet
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'เครดิตคงเหลือใน Wallet',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                      ),
                      Text(
                        '${balance.toStringAsFixed(0)} เครดิต',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: balance >= _finalPrice
                              ? const Color(0xFF52C41A)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 6. ปุ่มยืนยันการจอง & ข้อความเตือน 5 นาที
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleConfirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ยืนยันการจอง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Color(0xFFD46B08),
                ),
                SizedBox(width: 6),
                Text(
                  'ต้องชำระเครดิตภายใน 5 นาทีหลังยืนยันการจอง',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD46B08),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
