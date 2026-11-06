import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/api_constants.dart';
import 'shop_detail_screen.dart';
import 'welcome_screen.dart';
import 'admin/admin_main_navigation_screen.dart';
import 'owner/owner_main_navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedVehicleType = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShops();
    });
  }

  void _loadShops() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    shopProvider.searchShops(
      keyword: _searchController.text.trim(),
      vehicleType: _selectedVehicleType.isNotEmpty ? _selectedVehicleType : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_car_wash_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              widget.isGuest ? 'WashQ (โหมดผู้ใช้ทั่วไป)' : 'สวัสดี, ${authProvider.currentUser?.fullName ?? 'สมาชิก'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (authProvider.currentUser?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.shield, color: AppTheme.primaryColor),
              tooltip: 'แดชบอร์ดแอดมิน',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminMainNavigationScreen()),
                );
              },
            ),
          if (authProvider.currentUser?.isOwner == true)
            IconButton(
              icon: const Icon(Icons.storefront, color: AppTheme.primaryColor),
              tooltip: 'แดชบอร์ดเจ้าของร้าน',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerMainNavigationScreen()),
                );
              },
            ),
          if (!widget.isGuest)
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.error),
              tooltip: 'ออกจากระบบ',
              onPressed: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadShops(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อร้าน หรือชื่อบริการ (เช่น ดูดฝุ่น, ขัดสี)...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadShops();
                    },
                  ),
                ),
                onSubmitted: (_) => _loadShops(),
              ),
              const SizedBox(height: 16),

              // Filter Chips (ประเภทรถ)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ทั้งหมด', ''),
                    _buildFilterChip('รถยนต์', 'car'),
                    _buildFilterChip('รถ SUV', 'suv'),
                    _buildFilterChip('รถจักรยานยนต์', 'motorcycle'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ร้านล้างรถใกล้คุณ 📍',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${shopProvider.shops.length} ร้านที่พบ',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Shop Cards List
              if (shopProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (shopProvider.shops.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'ไม่พบร้านล้างรถในขณะนี้',
                          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shopProvider.shops.length,
                  itemBuilder: (context, index) {
                    final shop = shopProvider.shops[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopDetailScreen(shopId: shop.id),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover Image
                            Container(
                              height: 140,
                              width: double.infinity,
                              color: AppTheme.primaryLight,
                              child: shop.coverImage != null
                                  ? Image.network(
                                      '${ApiConstants.uploadsUrl}/${shop.coverImage}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.store, size: 48, color: AppTheme.primaryColor),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          shop.shopName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                          const SizedBox(width: 4),
                                          Text(
                                            shop.averageRating.toStringAsFixed(1),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            ' (${shop.reviewCount})',
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          shop.address,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'เวลาเปิด-ปิด: ${shop.openTime.substring(0, 5)} - ${shop.closeTime.substring(0, 5)} น.',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.accentColor, fontWeight: FontWeight.w600),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(90, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ShopDetailScreen(shopId: shop.id),
                                            ),
                                          );
                                        },
                                        child: const Text('จองคิว', style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedVehicleType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          setState(() => _selectedVehicleType = val ? value : '');
          _loadShops();
        },
      ),
    );
  }
}

