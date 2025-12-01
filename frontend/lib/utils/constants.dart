import 'package:flutter/material.dart';

// API Constants
class ApiConstants {
  // Backend API URL Configuration
  // This can be overridden at build time using --dart-define
  //
  // DEVELOPMENT:
  // - Android Emulator: 'http://10.0.2.2:8080'
  // - iOS Simulator: 'http://localhost:8080'
  // - Physical Device: 'http://YOUR_LOCAL_IP:8080'
  //
  // PRODUCTION:
  // Build command: flutter build apk --dart-define=API_BASE_URL=https://your-railway-domain.up.railway.app
  //
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.29.74:8080', // Development default - change for your local IP
  );
  
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String meEndpoint = '/api/auth/me';
  
  static const String photosEndpoint = '/api/photos';
  static const String uploadEndpoint = '/api/photos/upload';
  static const String myPhotosEndpoint = '/api/photos/my-photos';
  static const String sharedPhotosEndpoint = '/api/photos/shared';
  static const String viewPhotoEndpoint = '/api/photos/view';
  
  static const String usersEndpoint = '/api/users';
  static const String profileEndpoint = '/api/users/me';
}

// Storage Keys
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userData = 'user_data';
  static const String lastSyncTime = 'last_sync_time';
  static const String appTheme = 'app_theme';
  static const String notificationsEnabled = 'notifications_enabled';
}

// App Colors
class AppColors {
  static const Color primaryColor = Color(0xFF673AB7); // Deep Purple
  static const Color accentColor = Color(0xFF9C27B0); // Purple
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
}

// App Constants
class AppConstants {
  static const String appName = 'FaceShare';
  static const String appVersion = '1.0.0';
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png'];
}