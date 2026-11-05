class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String role; // 'member', 'owner', 'admin'
  final String status; // 'active', 'suspended'
  final double balance;
  final double pendingBalance;
  final int? shopId;
  final String? shopName;
  final String? shopStatus;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
    this.balance = 0.0,
    this.pendingBalance = 0.0,
    this.shopId,
    this.shopName,
    this.shopStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'active',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      pendingBalance: double.tryParse(json['pending_balance']?.toString() ?? '0') ?? 0.0,
      shopId: json['shop_id'],
      shopName: json['shop_name'],
      shopStatus: json['shop_status'],
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
}

