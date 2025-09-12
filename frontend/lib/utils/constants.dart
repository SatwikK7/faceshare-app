// API Constants
class ApiConstants {
  // Update this to your backend server IP address
  // For Android emulator, use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://10.0.2.2:8080';
  
  // For iOS simulator or physical device, use your computer's IP address
  // static const String baseUrl = 'http://192.168.1.100:8080';
  
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
  static const String sharedPhotosEndpoint = '/api/photos/shared';
  
  static const String usersEndpoint = '/api/users';
  static const String profileEndpoint = '/api/users/profile';
}

// Storage Keys
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userData = 'user_data';
  static const String lastSyncTime = 'last_sync_time';
  static const String appTheme = 'app_theme';
  static const String notificationsEnabled = 'notifications_enabled';
}

// App Constants
class AppConstants {
  static const String appName = 'FaceShare';
  static const String appVersion = '1.0.0';
  
  // Image constants
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'bmp'];
  static const double imageQuality = 0.8;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Grid constants
  static const int photoGridCrossAxisCount = 2;
  static const double photoGridAspectRatio = 1.0;
  static const double photoGridSpacing = 8.0;
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String authenticationError = 'Authentication failed. Please login again.';
  static const String uploadError = 'Failed to upload photo. Please try again.';
  static const String noPhotosFound = 'No photos found.';
  static const String cameraPermissionDenied = 'Camera permission is required to take photos.';
  static const String storagePermissionDenied = 'Storage permission is required to access photos.';
  static const String invalidImageFormat = 'Invalid image format. Please select a valid image.';
  static const String imageTooLarge = 'Image is too large. Please select a smaller image.';
}

// Success Messages
class SuccessMessages {
  static const String loginSuccess = 'Login successful!';
  static const String registrationSuccess = 'Registration successful!';
  static const String uploadSuccess = 'Photo uploaded successfully!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  static const String logoutSuccess = 'Logged out successfully!';
}

// Validation Messages
class ValidationMessages {
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String fullNameRequired = 'Full name is required';
  static const String fullNameTooShort = 'Full name must be at least 2 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
}

// Theme Constants
class AppTheme {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';
}

// Notification Types
class NotificationTypes {
  static const String photoShared = 'photo_shared';
  static const String photoProcessed = 'photo_processed';
  static const String faceRecognized = 'face_recognized';
}

// Processing Status
class ProcessingStatusConstants {
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String completed = 'COMPLETED';
  static const String failed = 'FAILED';
}