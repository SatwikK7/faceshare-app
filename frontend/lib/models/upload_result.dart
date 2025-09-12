// lib/models/upload_result.dart
class UploadResult {
  final bool success;
  final String message;
  final Photo? photo;
  final String? error;
  
  UploadResult({
    required this.success,
    required this.message,
    this.photo,
    this.error,
  });
  
  factory UploadResult.success(String message, Photo photo) {
    return UploadResult(
      success: true,
      message: message,
      photo: photo,
    );
  }
  
  factory UploadResult.error(String error) {
    return UploadResult(
      success: false,
      message: error,
      error: error,
    );
  }
}