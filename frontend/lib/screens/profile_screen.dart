import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/vehicle_provider.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';
import 'login_screen.dart';
import 'register_shop_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onSelectTab;
  const ProfileScreen({super.key, this.onSelectTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        auth.fetchProfile();
        Provider.of<WalletProvider>(context, listen: false).fetchMyWallet();
        Provider.of<VehicleProvider>(context, listen: false).fetchMyVehicles();
      }
    });
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('แก้ไขข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ - นามสกุล',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              if (newName.isEmpty || newPhone.isEmpty) {
                AppSnackBar.showError(context, 'กรุณากรอกข้อมูลให้ครบถ้วน');
                return;
              }
              Navigator.pop(ctx);
              final success = await authProvider.updateProfile(fullName: newName, phone: newPhone);
              if (mounted) {
                if (success) {
                  AppSnackBar.showSuccess(context, 'บันทึกข้อมูลส่วนตัวเรียบร้อยแล้ว');
                } else {
                  AppSnackBar.showError(context, authProvider.errorMessage ?? 'ไม่สามารถอัปเดตข้อมูลได้');
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่านเดิม',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่านใหม่',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'ยืนยันรหัสผ่านใหม่',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (newPassController.text.length < 6) {
                AppSnackBar.showError(context, 'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร');
                return;
              }
              if (newPassController.text != confirmPassController.text) {
                AppSnackBar.showError(context, 'รหัสผ่านใหม่ไม่ตรงกัน');
                return;
              }
              Navigator.pop(ctx);
              final success = await authProvider.changePassword(
                oldPassController.text,
                newPassController.text,
              );
              if (mounted) {
                if (success) {
                  AppSnackBar.showSuccess(context, 'เปลี่ยนรหัสผ่านสำเร็จ');
                } else {
                  AppSnackBar.showError(context, authProvider.errorMessage ?? 'รหัสผ่านเดิมไม่ถูกต้อง');
                }
              }
            },
            child: const Text('เปลี่ยนรหัส'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('คุณต้องการออกจากระบบ ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF1322),
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final user = authProvider.currentUser;
    final balance = walletProvider.wallet?.balance ?? 0.0;
    final carCount = vehicleProvider.vehicles.length;

    final displayName = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'ผู้ใช้งาน WashQ';
    final displayEmail = (user?.email.isNotEmpty == true) ? user!.email : 'ยังไม่มีอีเมล';
    final displayPhone = (user?.phone.isNotEmpty == true) ? user!.phone : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Profile Header (Matches WashQ Gradient Header)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 52, left: 24, right: 24, bottom: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0056D2), Color(0xFF0066FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Avatar with Border and Edit Badge
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0066FF),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F2B5C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name & Role Badge
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      user?.isAdmin == true
                          ? 'ผู้ดูแลระบบ (Admin)'
                          : user?.isOwner == true
                              ? 'เจ้าของร้านคาร์แคร์ (Owner)'
                              : 'สมาชิกทั่วไป (Member)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Stats Row (Wallet + My Cars)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Wallet Balance Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onSelectTab != null) {
                          widget.onSelectTab!(2); // Switch to Wallet tab
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F7FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet, color: Color(0xFF0066FF), size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text('กระเป๋าเงิน', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '฿${NumberFormat('#,##0').format(balance)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5C)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Cars Count Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onSelectTab != null) {
                          widget.onSelectTab!(3); // Switch to Cars tab
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7E6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.directions_car, color: Color(0xFFFA8C16), size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text('รถของฉัน', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$carCount คัน',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2B5C)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: บัญชีและความปลอดภัย
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'บัญชีและความปลอดภัย',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF0066FF),
                          title: 'ข้อมูลส่วนตัว',
                          subtitle: '$displayName • $displayPhone',
                          onTap: () => _showEditProfileDialog(context),
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildMenuTile(
                          icon: Icons.lock_outline,
                          iconColor: const Color(0xFF52C41A),
                          title: 'เปลี่ยนรหัสผ่าน',
                          subtitle: 'ตั้งรหัสผ่านใหม่เพื่อความปลอดภัย',
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 2: การบริการและร้านค้า
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'การบริการและร้านค้า',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFF722ED1),
                          title: 'ประวัติการจองของฉัน',
                          subtitle: 'ดูสถานะและรายการจองคิวที่ผ่านมา',
                          onTap: () {
                            if (widget.onSelectTab != null) {
                              widget.onSelectTab!(1); // Switch to Bookings tab
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildMenuTile(
                          icon: Icons.storefront_outlined,
                          iconColor: const Color(0xFF13C2C2),
                          title: 'สมัครเปิดร้านคาร์แคร์กับเรา',
                          subtitle: 'ร่วมเป็นพาร์ทเนอร์และรับลูกค้าผ่านระบบ',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterShopScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 3: ความช่วยเหลือและข้อมูลแอป
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ความช่วยเหลือและระบบ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF1890FF),
                          title: 'นโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA)',
                          subtitle: 'มาตรฐานความปลอดภัยของข้อมูล',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('นโยบาย PDPA'),
                                content: const Text(
                                  'ระบบ WashQ มีการเก็บรักษาข้อมูลของผู้ใช้อย่างปลอดภัยตามมาตรฐาน พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล ข้อมูลเบอร์โทรและการชำระเงินจะถูกเข้ารหัสเพื่อความปลอดภัยสูงสุด',
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('เข้าใจแล้ว')),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildMenuTile(
                          icon: Icons.info_outline,
                          iconColor: const Color(0xFF8C8C8C),
                          title: 'เวอร์ชันแอปพลิเคชัน',
                          subtitle: 'WashQ v1.0.0 (Production Release)',
                          onTap: null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: InkWell(
                onTap: () => _showLogoutConfirmDialog(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F0),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFCCC7)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Color(0xFFCF1322), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          color: Color(0xFFCF1322),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Color(0xFFBFBFBF), size: 20)
          : null,
      onTap: onTap,
    );
  }
}
