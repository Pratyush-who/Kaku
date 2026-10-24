import 'dart:convert';
import '../network/api_client.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final Map<String, dynamic> preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    this.bio = '',
    this.preferences = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// Resolves relative upload paths like "/uploads/avatars/..." to the full backend URL.
  String get effectiveAvatarUrl {
    final trimmed = avatarUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUrl = ApiClient.instance.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl$path';
  }

  /// Extracts 1-2 uppercase initials for avatar placeholder.
  String get initials {
    final source = displayName.trim().isNotEmpty
        ? displayName.trim()
        : name.trim().isNotEmpty
            ? name.trim()
            : 'U';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> prefs = {};
    if (json['preferences'] != null) {
      if (json['preferences'] is Map<String, dynamic>) {
        prefs = json['preferences'] as Map<String, dynamic>;
      } else if (json['preferences'] is String) {
        try {
          prefs = jsonDecode(json['preferences'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      preferences: prefs,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'preferences': preferences,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
