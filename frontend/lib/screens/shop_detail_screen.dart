import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/api_constants.dart';
import 'booking_screen.dart';
import 'login_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false).fetchShopDetail(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shop = shopProvider.selectedShop;

    if (shopProvider.isLoading || shop == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(shop.shopName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner
            Container(
              height: 200,
              width: double.infinity,
              color: AppTheme.primaryLight,
              child: shop.coverImage != null
                  ? Image.network(
                      '${ApiConstants.uploadsUrl}/${shop.coverImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.store, size: 64, color: AppTheme.primaryColor),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.store, size: 64, color: AppTheme.primaryColor),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              shop.averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Phone & Address
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(shop.phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(shop.address, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        'เวลาทำการ: ${shop.openTime.substring(0, 5)} - ${shop.closeTime.substring(0, 5)} น.',
                        style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),

                  if (shop.description != null && shop.description!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      shop.description!,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],

                  const Divider(height: 32),

                  // Services List
                  const Text(
                    'บริการและราคา 🧼',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  if (shop.services.isEmpty)
                    const Text('ยังไม่มีรายการบริการในขณะนี้', style: TextStyle(color: AppTheme.textMuted))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: shop.services.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final s = shop.services[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.cleaning_services, color: AppTheme.primaryColor),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('สำหรับ: ${s.vehicleType}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          trailing: Text(
                            '฿${s.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80), // Space for floating button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (!authProvider.isAuthenticated) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookingScreen(shop: shop)),
            );
          },
          child: const Text('จองคิวล้างรถเลย'),
        ),
      ),
    );
  }
}

