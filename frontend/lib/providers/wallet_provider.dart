import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/api_constants.dart';
import '../models/wallet_model.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.get(ApiConstants.wallet);
    _isLoading = false;

    if (response.success && response.data != null) {
      _wallet = WalletModel.fromJson(response.data);
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> generateTopUpQr(double amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.walletTopUpQr,
      body: {'amount': amount},
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmTopUp(double amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.walletTopUpConfirm,
      body: {'amount': amount},
    );

    _isLoading = false;

    if (response.success) {
      await fetchMyWallet();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestWithdrawal({
    required double amount,
    required String bankName,
    required String bankAccountName,
    required String bankAccountNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.post(
      ApiConstants.walletWithdraw,
      body: {
        'amount': amount,
        'bank_name': bankName,
        'bank_account_name': bankAccountName,
        'bank_account_number': bankAccountNumber,
      },
    );

    _isLoading = false;

    if (response.success) {
      await fetchMyWallet();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }
}

