import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../core/app_theme.dart';
import 'shop_detail_screen.dart';
import 'welcome_screen.dart';
import 'wallet_screen.dart';
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
  String _selectedFilter = 'nearby'; // 'nearby', 'car', 'motorcycle', 'suv', 'top_rated'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShops();
      if (!widget.isGuest) {
        Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();
      }
    });
  }

  void _loadShops() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    String? vt;
    if (_selectedFilter == 'car') vt = 'car';
    if (_selectedFilter == 'motorcycle') vt = 'motorcycle';
    if (_selectedFilter == 'suv') vt = 'suv';

    shopProvider.searchShops(
      keyword: _searchController.text.trim(),
      vehicleType: vt,
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
    final walletProvider = Provider.of<WalletProvider>(context);
    final user = authProvider.currentUser;
    final balance = walletProvider.wallet?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadShops();
          if (!widget.isGuest) walletProvider.fetchMyWallet();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Blue Header (Matches 2.1_Home.png)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0056D2), Color(0xFF0066FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location & Quick Action Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text('ในเมือง, ขอนแก่น', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400)),
                          ],
                        ),
                        Row(
                          children: [
                            if (!widget.isGuest)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        balance.toStringAsFixed(0),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (authProvider.currentUser?.isAdmin == true)
                              IconButton(
                                icon: const Icon(Icons.shield, color: Colors.white),
                                tooltip: 'แดชบอร์ดแอดมิน',
                                onPressed: () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminMainNavigationScreen()));
                                },
                              )
                            else if (authProvider.currentUser?.isOwner == true)
                              IconButton(
                                icon: const Icon(Icons.storefront, color: Colors.white),
                                tooltip: 'แดชบอร์ดเจ้าของร้าน',
                                onPressed: () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerMainNavigationScreen()));
                                },
                              )
                            else
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_none, color: Colors.white, size: 18),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Greeting
                    Text(
                      widget.isGuest ? 'สวัสดี, ผู้เยี่ยมชม' : 'สวัสดี, ${user?.fullName ?? 'สมาชิก'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Input with trailing filter button (Matches 2.1_Home.png)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาชื่อร้าน หรือชื่อบริการ...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _loadShops(),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                              onPressed: _loadShops,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips (Matches 2.1_Home.png)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('nearby', 'ใกล้ฉัน'),
                          const SizedBox(width: 8),
                          _buildFilterChip('car', 'รถยนต์'),
                          const SizedBox(width: 8),
                          _buildFilterChip('motorcycle', 'มอเตอร์ไซค์'),
                          const SizedBox(width: 8),
                          _buildFilterChip('suv', 'SUV'),
                          const SizedBox(width: 8),
                          _buildFilterChip('top_rated', '4★ ขึ้นไป'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Map Preview Card (Matches 2.1_Home.png)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0F8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Map Pins graphics
                      Positioned(
                        top: 20,
                        left: 40,
                        child: _buildMapPin('฿120', isPrimary: true),
                      ),
                      Positioned(
                        top: 15,
                        right: 40,
                        child: _buildMapPin('฿99', isPrimary: false),
                      ),
                      Positioned(
                        bottom: 45,
                        left: 140,
                        child: _buildMapPin('฿150', isPrimary: false),
                      ),

                      // Bottom Left Tag: 🏪 12 ร้านใกล้คุณ
                      Positioned(
                        bottom: 12,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.storefront, size: 14, color: AppTheme.primaryColor),
                              SizedBox(width: 6),
                              Text('12 ร้านใกล้คุณ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Right Button: เปิดแผนที่
                      Positioned(
                        bottom: 12,
                        right: 14,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(88, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            // Map dialog or notice
                          },
                          child: const Text('เปิดแผนที่', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section Header: "ร้านแนะนำใกล้คุณ" (Matches 2.1_Home.png)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('ร้านแนะนำใกล้คุณ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('ดูทั้งหมด', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              // Shop Cards List
              if (shopProvider.isLoading && shopProvider.shops.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (shopProvider.shops.isEmpty)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Center(
                    child: Text('ไม่พบร้านล้างรถตามเงื่อนไขที่ค้นหา', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shopProvider.shops.length,
                  itemBuilder: (ctx, i) {
                    final shop = shopProvider.shops[i];
                    return _buildShopCard(shop, i);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = key);
        _loadShops();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMapPin(String price, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFD6E4FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? AppTheme.primaryColor : const Color(0xFFFAAD14),
            ),
          ),
          const SizedBox(width: 4),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShopCard(dynamic shop, int index) {
    final colors = [
      const Color(0xFF0066FF),
      const Color(0xFF722ED1),
      const Color(0xFF00B96B),
      const Color(0xFFFA8C16),
    ];
    final color = colors[index % colors.length];

    final openTime = (shop.openTime ?? '08:00').toString().substring(0, 5);
    final closeTime = (shop.closeTime ?? '18:00').toString().substring(0, 5);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left squircle image/icon (Matches 2.1_Home.png)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 14),

            // Middle details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text(
                        '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount}) • 1.2 กม.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '$openTime – $closeTime',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tag: • คิวว่างวันนี้ 6 คิว
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FFED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '• คิวว่างวันนี้ 6 คิว',
                      style: TextStyle(fontSize: 11, color: Color(0xFF389E0D), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Right Bottom Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SizedBox(height: 46),
                Text('เริ่มต้น', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                Text(
                  '฿120',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
