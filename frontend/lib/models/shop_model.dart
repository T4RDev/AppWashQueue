class ShopModel {
  final int id;
  final String shopName;
  final String phone;
  final String? description;
  final String address;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final bool acceptsMotorcycle;
  final bool acceptsCar;
  final bool acceptsSuv;
  final double averageRating;
  final int reviewCount;
  final String? coverImage;
  final double? distanceKm;
  final List<ServiceModel> services;
  final List<TimeSlotModel> timeSlots;
  final List<String> images;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.phone,
    this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    this.acceptsMotorcycle = true,
    this.acceptsCar = true,
    this.acceptsSuv = true,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.coverImage,
    this.distanceKm,
    this.services = const [],
    this.timeSlots = const [],
    this.images = const [],
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      openTime: json['open_time'] ?? '08:00:00',
      closeTime: json['close_time'] ?? '18:00:00',
      acceptsMotorcycle: json['accepts_motorcycle'] == 1 || json['accepts_motorcycle'] == true,
      acceptsCar: json['accepts_car'] == 1 || json['accepts_car'] == true,
      acceptsSuv: json['accepts_suv'] == 1 || json['accepts_suv'] == true,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      coverImage: json['cover_image'],
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      services: (json['services'] as List<dynamic>?)?.map((s) => ServiceModel.fromJson(s)).toList() ?? [],
      timeSlots: (json['time_slots'] as List<dynamic>?)?.map((t) => TimeSlotModel.fromJson(t)).toList() ?? [],
      images: (json['images'] as List<dynamic>?)?.map((i) => (i['image_url'] ?? i).toString()).toList() ?? [],
    );
  }
}

class ServiceModel {
  final int id;
  final String name;
  final String vehicleType;
  final double price;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.price,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'car',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class TimeSlotModel {
  final int id;
  final String startTime;
  final String endTime;
  final int capacity;
  final String vehicleType;
  final int bookedCount;
  final int availableCount;
  final bool isAvailable;

  TimeSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.vehicleType = 'all',
    this.bookedCount = 0,
    this.availableCount = 1,
    this.isAvailable = true,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      capacity: json['capacity'] ?? 1,
      vehicleType: json['vehicle_type'] ?? 'all',
      bookedCount: json['booked_count'] ?? 0,
      availableCount: json['available_count'] ?? 1,
      isAvailable: json['is_available'] ?? true,
    );
  }

  String get timeRangeFormatted {
    final start = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$start - $end น.';
  }
}

