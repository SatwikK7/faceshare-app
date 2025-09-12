// lib/models/photo.dart
import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo {
  final int id;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final int userId;
  final String? userFullName;
  final ProcessingStatus processingStatus;
  final int facesDetected;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Photo({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    required this.userId,
    this.userFullName,
    required this.processingStatus,
    required this.facesDetected,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoToJson(this);
  
  String get imageUrl => 'http://localhost:8080/api/photos/view/${id}';
  
  bool get isProcessing => processingStatus == ProcessingStatus.processing || 
                          processingStatus == ProcessingStatus.pending;
  
  bool get isCompleted => processingStatus == ProcessingStatus.completed;
  
  bool get hasFailed => processingStatus == ProcessingStatus.failed;
  
  String get statusText {
    switch (processingStatus) {
      case ProcessingStatus.pending:
        return 'Pending';
      case ProcessingStatus.processing:
        return 'Processing';
      case ProcesssingStatus.completed:
        return 'Completed';
      case ProcessingStatus.failed:
        return 'Failed';
    }
  }
  
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    
    final bytes = fileSize!;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

enum ProcessingStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('FAILED')
  failed,
}