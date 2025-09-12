// lib/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  final String fullName;
  final String? profileImageUrl;
  final DateTime? createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.profileImageUrl,
    this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  String get firstName {
    return fullName.split(' ').first;
  }
  
  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.length > 0 ? fullName[0].toUpperCase() : 'U';
  }
}