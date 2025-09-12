// lib/models/shared_photo.dart
import 'package:json_annotation/json_annotation.dart';
import 'photo.dart';
import 'user.dart';

part 'shared_photo.g.dart';

@JsonSerializable()
class SharedPhoto {
  final int id;
  final int photoId;
  final int sharedWithUserId;
  final int sharedByUserId;
  final DateTime sharedAt;
  final bool viewed;
  final Photo? photo;
  final User? sharedByUser;
  
  SharedPhoto({
    required this.id,
    required this.photoId,
    required this.sharedWithUserId,
    required this.sharedByUserId,
    required this.sharedAt,
    required this.viewed,
    this.photo,
    this.sharedByUser,
  });
  
  factory SharedPhoto.fromJson(Map<String, dynamic> json) => _$SharedPhotoFromJson(json);
  Map<String, dynamic> toJson() => _$SharedPhotoToJson(this);
  
  String get sharedByName => sharedByUser?.fullName ?? 'Someone';
  String get imageUrl => photo?.imageUrl ?? '';
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sharedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}