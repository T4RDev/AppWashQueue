import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../models/shop_model.dart';

class ShopProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ShopModel> _shops = [];
  ShopModel? _selectedShop;
  List<TimeSlotModel> _availableSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ShopModel> get shops => _shops;
  ShopModel? get selectedShop => _selectedShop;
  List<TimeSlotModel> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> searchShops({
    String? keyword,
    String? serviceName,
    String? vehicleType,
    double? userLat,
    double? userLng,
    double? minRating,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = <String, dynamic>{};
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (serviceName != null && serviceName.isNotEmpty) queryParams['service_name'] = serviceName;
    if (vehicleType != null && vehicleType.isNotEmpty) queryParams['vehicle_type'] = vehicleType;
    if (userLat != null && userLng != null) {
      queryParams['user_lat'] = userLat;
      queryParams['user_lng'] = userLng;
    }
    if (minRating != null) queryParams['min_rating'] = minRating;

    final response = await _apiService.get(ApiConstants.shops, queryParams: queryParams);
    _isLoading = false;

    if (response.success && response.data != null) {
      _shops = (response.data as List<dynamic>)
          .map((item) => ShopModel.fromJson(item))
          .toList();
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<bool> fetchShopDetail(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.get('${ApiConstants.shops}/$shopId');
    _isLoading = false;

    if (response.success && response.data != null) {
      _selectedShop = ShopModel.fromJson(response.data);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAvailableSlots(int shopId, String date, {String? vehicleType}) async {
    _availableSlots = [];
    notifyListeners();

    final queryParams = <String, dynamic>{'date': date};
    if (vehicleType != null) queryParams['vehicle_type'] = vehicleType;

    final response = await _apiService.get(
      '${ApiConstants.shops}/$shopId/available-slots',
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      final slotsData = response.data['slots'] as List<dynamic>?;
      if (slotsData != null) {
        _availableSlots = slotsData.map((s) => TimeSlotModel.fromJson(s)).toList();
      }
    }
    notifyListeners();
  }
}

