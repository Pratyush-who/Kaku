class InvitationModel {
  final String id;
  final String projectId;
  final String email;
  final String role; // 'editor', 'viewer'
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final String? createdBy;
  final DateTime? createdAt;
  final bool userExists;

  const InvitationModel({
    required this.id,
    required this.projectId,
    required this.email,
    required this.role,
    this.expiresAt,
    this.acceptedAt,
    this.createdBy,
    this.createdAt,
    this.userExists = false,
  });

  bool get isAccepted => acceptedAt != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'editor',
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
      acceptedAt: json['acceptedAt'] != null ? DateTime.tryParse(json['acceptedAt'] as String) : null,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      userExists: json['userExists'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'email': email,
      'role': role,
      'expiresAt': expiresAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'userExists': userExists,
    };
  }
}

class InvitationCreateResponse {
  final InvitationModel invitation;
  final String? rawToken;

  const InvitationCreateResponse({
    required this.invitation,
    this.rawToken,
  });

  factory InvitationCreateResponse.fromJson(Map<String, dynamic> json) {
    return InvitationCreateResponse(
      invitation: InvitationModel.fromJson(json['invitation'] as Map<String, dynamic>),
      rawToken: json['token'] as String?,
    );
  }
}
