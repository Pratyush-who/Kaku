import 'user_model.dart';

class ProjectMemberModel {
  final String projectId;
  final String userId;
  final String role; // 'owner', 'editor', 'viewer'
  final DateTime? joinedAt;
  final UserModel? user;

  const ProjectMemberModel({
    required this.projectId,
    required this.userId,
    required this.role,
    this.joinedAt,
    this.user,
  });

  bool get isOwner => role.toLowerCase() == 'owner';

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      projectId: json['projectId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      role: json['role'] as String? ?? 'viewer',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'] as String) : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'userId': userId,
      'role': role,
      'joinedAt': joinedAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
