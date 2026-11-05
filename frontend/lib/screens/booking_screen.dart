import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/shop_model.dart';
import '../models/vehicle_model.dart';
import '../providers/shop_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/wallet_provider.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import 'wallet_screen.dart';
import 'my_cars_screen.dart';

class BookingScreen extends StatefulWidget {
  final ShopModel shop;
  const BookingScreen({super.key, required this.shop});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  VehicleModel? _selectedVehicle;
  ServiceModel? _selectedService;
  TimeSlotModel? _selectedSlot;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchMyVehicles();
      Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();
      _fetchSlots();
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
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    final price = _selectedService!.price;
    final currentBalance = walletProvider.wallet?.balance ?? 0.0;

    // ตรวจสอบยอดเงินคงเหลือในกระเป๋า (1.3.2 ข้อ 6)
    if (currentBalance < price) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ยอดเงินใน Wallet ไม่เพียงพอ'),
          content: Text(
            'ค่าบริการ ฿${price.toStringAsFixed(0)} แต่คุณมียอดเงินคงเหลือ ฿${currentBalance.toStringAsFixed(0)}\nต้องการเติมเงินเลยหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              child: const Text('ไปที่หน้าเติมเงิน'),
            ),
          ],
        ),
      );
      return;
    }

    // ยืนยันการตัดเงินและจองคิว
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการชำระเงินและจองคิว'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ร้าน: ${widget.shop.shopName}'),
            Text('บริการ: ${_selectedService!.name}'),
            Text('รถ: ${_selectedVehicle!.plateNumber} (${_selectedVehicle!.vehicleTypeThai})'),
            Text('วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            Text('เวลา: ${_selectedSlot!.timeRangeFormatted}'),
            const Divider(height: 20),
            Text(
              'ยอดเงินที่จะตัดจาก Wallet: ฿${price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยืนยันตัดเงินทันที'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await bookingProvider.createBooking(
      shopId: widget.shop.id,
      vehicleId: _selectedVehicle!.id,
      serviceId: _selectedService!.id,
      timeSlotId: _selectedSlot!.id,
      bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      discountCode: _discountController.text.trim().isNotEmpty ? _discountController.text.trim() : null,
    );

    if (!mounted) return;

    if (result != null) {
      await walletProvider.fetchMyWallet(); // อัปเดต balance
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('จองคิวสำเร็จ! 🎉'),
          content: Text(
            'รหัสการจองของคุณคือ ${result['booking_code']}\nระบบได้ตัดเงินจาก Wallet และแจ้งเตือนร้านค้าเรียบร้อยแล้ว',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // ปิด Dialog
                Navigator.pop(context); // ปิดหน้า Booking
              },
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    } else {
      AppSnackBar.showError(context, bookingProvider.errorMessage ?? 'จองคิวไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('จองคิวล้างรถ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. เลือกรถ
            const Text(
              '1. เลือกรถที่จะเข้ารับบริการ 🚗',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (vehicleProvider.vehicles.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('คุณยังไม่มีข้อมูลรถที่บันทึกไว้'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('เพิ่มข้อมูลรถของคุณ'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyCarsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<VehicleModel>(
                value: _selectedVehicle,
                hint: const Text('แตะเพื่อเลือกรถที่บันทึกไว้'),
                items: vehicleProvider.vehicles.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text('${v.plateNumber} (${v.brand} ${v.model} - ${v.vehicleTypeThai})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedVehicle = val);
                  _fetchSlots();
                },
              ),
            const SizedBox(height: 20),

            // 2. เลือกบริการ
            const Text(
              '2. เลือกบริการที่ต้องการ 🧼',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ServiceModel>(
              value: _selectedService,
              hint: const Text('แตะเพื่อเลือกบริการ'),
              items: widget.shop.services.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text('${s.name} - ฿${s.price.toStringAsFixed(0)} (${s.vehicleType})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedService = val),
            ),
            const SizedBox(height: 20),

            // 3. เลือกวันที่
            const Text(
              '3. วันที่จะเข้าใช้บริการ 📅',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _fetchSlots();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy (EEEE)').format(_selectedDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. เลือกสล็อตเวลา
            const Text(
              '4. สล็อตเวลาและจำนวนคิวว่าง ⏱️',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (shopProvider.availableSlots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('ไม่มีสล็อตเวลาว่างในวันนี้ หรือร้านปิดทำการ', style: TextStyle(color: AppTheme.textMuted)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shopProvider.availableSlots.map((slot) {
                  final isSelected = _selectedSlot?.id == slot.id;
                  final isAvailable = slot.isAvailable;
                  return ChoiceChip(
                    label: Text(
                      '${slot.timeRangeFormatted}\n(ว่าง ${slot.availableCount}/${slot.capacity} คิว)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: !isAvailable
                            ? Colors.grey
                            : isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    onSelected: isAvailable
                        ? (val) {
                            setState(() => _selectedSlot = val ? slot : null);
                          }
                        : null,
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),

            // 5. โค้ดส่วนลด (1.3.4 ข้อ 5)
            const Text(
              '5. ส่วนลดของระบบ (Discount Code)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                hintText: 'กรอกโค้ดส่วนลด (เช่น WASH10)',
                prefixIcon: Icon(Icons.discount_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // สรุปยอดเงิน & Wallet
            Card(
              color: AppTheme.primaryLight.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ยอดเงินใน Wallet ของคุณ:'),
                        Text(
                          '฿${(walletProvider.wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ค่าบริการ:'),
                        Text(
                          '฿${(_selectedService?.price ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ยืนยันการจอง
            ElevatedButton(
              onPressed: _handleConfirmBooking,
              child: const Text('ยืนยันและชำระเงินผ่าน Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

