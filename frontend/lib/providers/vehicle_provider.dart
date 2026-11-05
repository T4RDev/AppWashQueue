import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../models/vehicle_model.dart';

class VehicleProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.get(ApiConstants.vehicles);
    _isLoading = false;

    if (response.success && response.data != null) {
      _vehicles = (response.data as List<dynamic>)
          .map((item) => VehicleModel.fromJson(item))
          .toList();
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<bool> addVehicle({
    required String plateNumber,
    required String vehicleType,
    required String brand,
    required String model,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.vehicles,
      body: {
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
      },
    );

    _isLoading = false;

    if (response.success) {
      await fetchMyVehicles();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVehicle({
    required int id,
    String? plateNumber,
    String? vehicleType,
    String? brand,
    String? model,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.put(
      '${ApiConstants.vehicles}/$id',
      body: {
        if (plateNumber != null) 'plate_number': plateNumber,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
      },
    );

    _isLoading = false;

    if (response.success) {
      await fetchMyVehicles();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.delete('${ApiConstants.vehicles}/$id');
    _isLoading = false;

    if (response.success) {
      _vehicles.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }
}

