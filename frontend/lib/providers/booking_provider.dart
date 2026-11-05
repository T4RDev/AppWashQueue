import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyBookings({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = status != null ? {'status': status} : null;
    final response = await _apiService.get(ApiConstants.myBookings, queryParams: queryParams);
    _isLoading = false;

    if (response.success && response.data != null) {
      _bookings = (response.data as List<dynamic>)
          .map((item) => BookingModel.fromJson(item))
          .toList();
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createBooking({
    required int shopId,
    required int vehicleId,
    required int serviceId,
    required int timeSlotId,
    required String bookingDate,
    String? discountCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.bookings,
      body: {
        'shop_id': shopId,
        'vehicle_id': vehicleId,
        'service_id': serviceId,
        'time_slot_id': timeSlotId,
        'booking_date': bookingDate,
        if (discountCode != null && discountCode.isNotEmpty) 'discount_code': discountCode,
      },
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      notifyListeners();
      return response.data as Map<String, dynamic>;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post('${ApiConstants.bookings}/$bookingId/cancel');
    _isLoading = false;

    if (response.success) {
      await fetchMyBookings();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReview(int bookingId, int rating, String? comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.reviews,
      body: {
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
      },
    );

    _isLoading = false;

    if (response.success) {
      await fetchMyBookings();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }
}

