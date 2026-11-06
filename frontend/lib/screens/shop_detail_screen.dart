import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/auth_provider.dart';
import '../models/shop_model.dart';
import '../core/app_theme.dart';
import 'booking_screen.dart';
import 'login_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final dynamic shop;
  final int? shopId;

  const ShopDetailScreen({super.key, this.shop, this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  String _selectedVehicleType = 'car';
  int _selectedServiceIndex = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final id = widget.shop is ShopModel ? (widget.shop as ShopModel).id : widget.shopId ?? 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false).fetchShopDetail(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final shop = shopProvider.selectedShop ?? (widget.shop is ShopModel ? widget.shop as ShopModel : null);

    if (shop == null && shopProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentShop = shop ?? ShopModel(
      id: 1,
      shopName: 'คาร์แคร์ สะอาดใส',
      phone: '0812345678',
      description: 'ศูนย์บริการล้างรถและเคลือบสีครบวงจร',
      address: 'ในเมือง, ขอนแก่น • 1.2 กม.',
      latitude: 13.736717,
      longitude: 100.560787,
      openTime: '08:00',
      closeTime: '18:00',
      averageRating: 4.8,
      reviewCount: 126,
    );

    // Mock services matching 2.2_Shop_Detail.png
    final services = [
      {'name': 'ล้างอัดฉีด', 'desc': 'รถยนต์ • ประมาณ 45 นาที', 'price': 150},
      {'name': 'ดูดฝุ่นภายใน', 'desc': 'รถยนต์ • ประมาณ 30 นาที', 'price': 80},
      {'name': 'เคลือบสี', 'desc': 'รถยนต์ • ประมาณ 60 นาที', 'price': 350},
    ];

    final selectedService = services[_selectedServiceIndex];
    final totalPrice = selectedService['price'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Header Banner (Matches 2.2_Shop_Detail.png)
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0056D2), Color(0xFF0072FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Back Button
                    Positioned(
                      top: 10,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // Star / Favorite Button
                    Positioned(
                      top: 10,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.star : Icons.star_border,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _isFavorite = !_isFavorite),
                        ),
                      ),
                    ),
                    // Center Vehicle Illustration
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_car_wash,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shop Info Section (Matches 2.2_Shop_Detail.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentShop.shopName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FFED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.circle, color: Color(0xFF52C41A), size: 8),
                            SizedBox(width: 4),
                            Text('เปิดอยู่', style: TextStyle(color: Color(0xFF389E0D), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating, Distance, Opening Hours
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                      const SizedBox(width: 4),
                      Text(
                        '${currentShop.rating.toStringAsFixed(1)} (${currentShop.reviewCount} รีวิว) • 📍 1.2 กม. • 🕒 08:00 – 18:00',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3 Quick Stat Cards in a row (Matches 2.2_Shop_Detail.png)
                  Row(
                    children: [
                      _buildQuickStat('วันให้บริการ', 'จ. – ส.', AppTheme.textPrimary),
                      const SizedBox(width: 10),
                      _buildQuickStat('คิวว่างพรุ่งนี้', '6 คิว', const Color(0xFF389E0D)),
                      const SizedBox(width: 10),
                      _buildQuickStat('ประเภทรถ', '3 ประเภท', AppTheme.textPrimary),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // สล็อตพรุ่งนี้ (Matches 2.2_Shop_Detail.png)
                  const Text('สล็อตพรุ่งนี้ • อ. 27 ต.ค.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildSlotChip('08:00', 'ว่าง 2', isAvailable: true),
                      const SizedBox(width: 8),
                      _buildSlotChip('10:00', 'ว่าง 1', isAvailable: true),
                      const SizedBox(width: 8),
                      _buildSlotChip('13:00', 'เต็ม', isAvailable: false),
                      const SizedBox(width: 8),
                      _buildSlotChip('15:00', 'ว่าง 3', isAvailable: true),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // บริการและราคา (Matches 2.2_Shop_Detail.png)
                  const Text('บริการและราคา', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),

                  // Vehicle Type Toggle Buttons
                  Row(
                    children: [
                      _buildVehicleToggle('car', 'รถยนต์', Icons.directions_car),
                      const SizedBox(width: 8),
                      _buildVehicleToggle('suv', 'SUV', Icons.airport_shuttle),
                      const SizedBox(width: 8),
                      _buildVehicleToggle('motorcycle', 'จักรยานยนต์', Icons.two_wheeler),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Service Items with radio checkmark
                  ...List.generate(services.length, (idx) {
                    final isSelected = _selectedServiceIndex == idx;
                    final s = services[idx];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedServiceIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE8F3FF) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.directions_car_filled,
                                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(s['desc'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Text(
                              '฿${s['price']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300, width: 1.5),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 90), // Space for bottom bar
          ],
        ),
      ),

      // Bottom Sticky Booking Bar (Matches 2.2_Shop_Detail.png)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ราคารวม', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text(
                    '$totalPrice เครดิต',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () {
                  if (!authProvider.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookingScreen(shop: currentShop)),
                  );
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: const Text('จองคิวเลย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String val, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valColor), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotChip(String time, String count, {required bool isAvailable}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isAvailable ? const Color(0xFFF6FFED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isAvailable ? const Color(0xFFB7EB8F) : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isAvailable ? const Color(0xFF389E0D) : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(
                fontSize: 11,
                color: isAvailable ? const Color(0xFF389E0D) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleToggle(String key, String label, IconData icon) {
    final isSelected = _selectedVehicleType == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVehicleType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
