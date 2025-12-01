import '../utils/constants.dart';

class Photo {
  final int id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final int userId;
  final String userFullName;
  final String processingStatus;
  final int facesDetected;
  final DateTime createdAt;
  final DateTime updatedAt;

  Photo({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.userId,
    required this.userFullName,
    required this.processingStatus,
    required this.facesDetected,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? 0,
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      processingStatus: json['processingStatus'] ?? 'PENDING',
      facesDetected: json['facesDetected'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'userId': userId,
      'userFullName': userFullName,
      'processingStatus': processingStatus,
      'facesDetected': facesDetected,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get imageUrl {
    // Use ApiConstants baseUrl for consistency
    return '${ApiConstants.baseUrl}/api/photos/view/$id';
  }
  
  bool get isProcessed => processingStatus == 'COMPLETED';
  bool get isProcessing => processingStatus == 'PROCESSING';
  bool get hasFaces => facesDetected > 0;
}