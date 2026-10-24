class RecentBoardModel {
  final String id;
  final String projectId;
  final String projectName;
  final String name;
  final int revision;
  final String role;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecentBoardModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.name,
    this.revision = 0,
    this.role = 'editor',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RecentBoardModel.fromJson(Map<String, dynamic> json) {
    return RecentBoardModel(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      projectName: json['projectName'] as String? ?? 'Workspace Project',
      name: json['name'] as String? ?? 'Untitled Board',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'editor',
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'projectName': projectName,
    'name': name,
    'revision': revision,
    'role': role,
    'createdBy': createdBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
