class BookingModel {
  final int id;
  final String bookingCode;
  final String bookingDate;
  final String status;
  final String paymentStatus;
  final double originalPrice;
  final double discountAmount;
  final double finalPrice;
  final double shopShareAmount;
  final int shopId;
  final String shopName;
  final String? shopPhone;
  final String? shopAddress;
  final String startTime;
  final String endTime;
  final String plateNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final String serviceName;
  final int? reviewId;
  final int? myRating;
  final String createdAt;

  BookingModel({
    required this.id,
    required this.bookingCode,
    required this.bookingDate,
    required this.status,
    required this.paymentStatus,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
    this.shopShareAmount = 0.0,
    required this.shopId,
    required this.shopName,
    this.shopPhone,
    this.shopAddress,
    required this.startTime,
    required this.endTime,
    required this.plateNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.serviceName,
    this.reviewId,
    this.myRating,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      bookingCode: json['booking_code'] ?? '',
      bookingDate: (json['booking_date'] ?? '').toString().split('T')[0],
      status: json['status'] ?? 'pending_service',
      paymentStatus: json['payment_status'] ?? 'paid',
      originalPrice: double.tryParse(json['original_price']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      finalPrice: double.tryParse(json['final_price']?.toString() ?? '0') ?? 0.0,
      shopShareAmount: double.tryParse(json['shop_share_amount']?.toString() ?? '0') ?? 0.0,
      shopId: json['shop_id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      shopPhone: json['shop_phone'],
      shopAddress: json['shop_address'],
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'car',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      serviceName: json['service_name'] ?? '',
      reviewId: json['review_id'],
      myRating: json['my_rating'],
      createdAt: json['created_at'] ?? '',
    );
  }

  String get statusThai {
    switch (status) {
      case 'pending_service':
        return 'รอเข้ารับบริการ';
      case 'checked_in':
        return 'เข้ารับบริการแล้ว';
      case 'in_service':
        return 'กำลังให้บริการ';
      case 'completed':
        return 'บริการเสร็จสิ้น';
      case 'no_show':
        return 'ไม่มาตามนัด';
      case 'cancelled_by_user':
        return 'ยกเลิกโดยสมาชิก';
      case 'cancelled_by_shop':
        return 'ยกเลิกโดยร้านค้า';
      default:
        return status;
    }
  }

  String get slotTimeRange => '${startTime.length >= 5 ? startTime.substring(0, 5) : startTime} - ${endTime.length >= 5 ? endTime.substring(0, 5) : endTime}';
  String get vehiclePlate => plateNumber;

  bool get canCancel => status == 'pending_service';
  bool get canReview => status == 'completed' && reviewId == null;
}

