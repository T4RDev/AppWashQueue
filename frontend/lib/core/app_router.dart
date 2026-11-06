import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/owner/owner_main_navigation_screen.dart';
import '../screens/admin/admin_main_navigation_screen.dart';

class AppRouter {
  static Widget getHomeScreenForUser(UserModel? user, {bool isGuest = false}) {
    if (isGuest || user == null) {
      return const MainNavigationScreen(isGuest: true);
    }
    if (user.isAdmin) {
      return const AdminMainNavigationScreen();
    }
    if (user.isOwner) {
      return const OwnerMainNavigationScreen();
    }
    return const MainNavigationScreen(isGuest: false);
  }
}
