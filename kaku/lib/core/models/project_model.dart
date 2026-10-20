class ProjectModel {
  final String id;
  final String ownerId;
  final String name;
  final String userRole; // 'owner', 'editor', 'viewer'
  final int memberCount;
  final int boardCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.userRole = 'owner',
    this.memberCount = 1,
    this.boardCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOwner => userRole.toLowerCase() == 'owner';
  bool get canEdit => userRole.toLowerCase() == 'owner' || userRole.toLowerCase() == 'editor';

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Project',
      userRole: json['userRole'] as String? ?? 'owner',
      memberCount: json['memberCount'] as int? ?? 1,
      boardCount: json['boardCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'userRole': userRole,
      'memberCount': memberCount,
      'boardCount': boardCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? userRole,
    int? memberCount,
    int? boardCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      userRole: userRole ?? this.userRole,
      memberCount: memberCount ?? this.memberCount,
      boardCount: boardCount ?? this.boardCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
