class VehicleModel {
  final int id;
  final String plateNumber;
  final String vehicleType; // 'motorcycle', 'car', 'suv'
  final String brand;
  final String model;
  final String? createdAt;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      plateNumber: json['plate_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'car',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plate_number': plateNumber,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
    };
  }

  String get vehicleTypeThai {
    switch (vehicleType) {
      case 'motorcycle':
        return 'รถจักรยานยนต์';
      case 'car':
        return 'รถยนต์';
      case 'suv':
        return 'รถ SUV';
      default:
        return 'รถยนต์';
    }
  }
}

