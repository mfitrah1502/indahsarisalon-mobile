import 'package:flutter/foundation.dart';

class AppSession {
  static int? userId;
  static String? userName;
  static String? userRole;
  static String? userEmail;
  static String? userAvatar;
  static String? userTier; // Added for loyalty feature

  // Theme management
  static final ValueNotifier<bool> themeNotifier = ValueNotifier<bool>(false);
  static bool get isDarkMode => themeNotifier.value;
  static set isDarkMode(bool val) => themeNotifier.value = val;

  static void clear() {
    userId = null;
    userName = null;
    userRole = null;
    userEmail = null;
    userAvatar = null;
    userTier = null;
  }
}
