import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  // รองรับทั้ง Flutter Web, Android Emulator และ iOS/Desktop
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  static String get uploadsUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {}
    return 'http://localhost:5000';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleAuth = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';

  // Vehicles
  static const String vehicles = '/vehicles';

  // Shops
  static const String shops = '/shops';
  static const String shopRegister = '/shops/register';

  // Owner
  static const String ownerShop = '/owner/shop';
  static const String ownerOperatingDays = '/owner/operating-days';
  static const String ownerTimeSlots = '/owner/time-slots';
  static const String ownerServices = '/owner/services';
  static const String ownerBookings = '/owner/bookings';
  static const String ownerStats = '/owner/stats';
  static const String ownerWithdraw = '/owner/withdraw';

  // Bookings
  static const String bookings = '/bookings';
  static const String myBookings = '/bookings/my';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTopUpQr = '/wallet/topup/qr';
  static const String walletTopUpConfirm = '/wallet/topup/confirm';
  static const String walletWithdraw = '/wallet/withdraw';

  // Reviews
  static const String reviews = '/reviews';

  // Admin
  static const String adminOverview = '/admin/overview';
  static const String adminShops = '/admin/shops';
  static const String adminUsers = '/admin/users';
  static const String adminDiscounts = '/admin/discounts';
  static const String adminWithdrawals = '/admin/withdrawals';
  static const String adminBookings = '/admin/bookings';

  // Notifications
  static const String notifications = '/notifications';
}
