class WalletModel {
  final int id;
  final double balance;
  final double pendingBalance;
  final List<WalletTransactionModel> transactions;

  WalletModel({
    required this.id,
    required this.balance,
    required this.pendingBalance,
    this.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? 0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      pendingBalance: double.tryParse(json['pending_balance']?.toString() ?? '0') ?? 0.0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((t) => WalletTransactionModel.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class WalletTransactionModel {
  final int id;
  final double amount;
  final String type; // 'topup', 'booking_payment', 'booking_earning', 'refund', 'withdrawal'
  final String status;
  final String? referenceId;
  final String? slipUrl;
  final String? notes;
  final String createdAt;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.referenceId,
    this.slipUrl,
    this.notes,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? '',
      status: json['status'] ?? 'completed',
      referenceId: json['reference_id'],
      slipUrl: json['slip_url'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isPositive => type == 'topup' || type == 'booking_earning' || type == 'refund';

  String get typeThai {
    switch (type) {
      case 'topup':
        return 'เติมเงินเข้ากระเป๋า';
      case 'booking_payment':
        return 'ชำระค่าบริการจองคิว';
      case 'booking_earning':
        return 'รายได้จากการให้บริการ';
      case 'refund':
        return 'รับเงินคืนจากการยกเลิก';
      case 'withdrawal':
        return 'ถอนเงินเข้าบัญชีธนาคาร';
      default:
        return type;
    }
  }
}

