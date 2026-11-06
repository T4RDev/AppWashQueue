import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token == null) return false;
    return await fetchProfile();
  }

  Future<bool> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.get(ApiConstants.me);
    _isLoading = false;

    if (response.success && response.data != null) {
      _currentUser = UserModel.fromJson(response.data);
      notifyListeners();
      return true;
    } else {
      await _apiService.setToken(null);
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      final token = response.data['token'];
      await _apiService.setToken(token);
      _currentUser = UserModel.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    List<Map<String, dynamic>>? vehicles,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.register,
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        if (vehicles != null && vehicles.isNotEmpty) 'vehicles': vehicles,
      },
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      final token = response.data['token'];
      await _apiService.setToken(token);
      _currentUser = UserModel.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.put(
      ApiConstants.updateProfile,
      body: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );

    _isLoading = false;
    if (response.success) {
      await fetchProfile();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.put(
      ApiConstants.changePassword,
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );

    _isLoading = false;
    if (response.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.setToken(null);
    _currentUser = null;
    notifyListeners();
  }
}

