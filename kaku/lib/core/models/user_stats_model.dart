class UserStatsModel {
  final int ownedProjectsCount;
  final int sharedProjectsCount;
  final int totalProjectsCount;
  final int createdBoardsCount;
  final int totalBoardsCount;
  final DateTime? accountCreatedAt;

  const UserStatsModel({
    this.ownedProjectsCount = 0,
    this.sharedProjectsCount = 0,
    this.totalProjectsCount = 0,
    this.createdBoardsCount = 0,
    this.totalBoardsCount = 0,
    this.accountCreatedAt,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      ownedProjectsCount: (json['ownedProjectsCount'] as num?)?.toInt() ?? 0,
      sharedProjectsCount: (json['sharedProjectsCount'] as num?)?.toInt() ?? 0,
      totalProjectsCount: (json['totalProjectsCount'] as num?)?.toInt() ?? 0,
      createdBoardsCount: (json['createdBoardsCount'] as num?)?.toInt() ?? 0,
      totalBoardsCount: (json['totalBoardsCount'] as num?)?.toInt() ?? 0,
      accountCreatedAt: json['accountCreatedAt'] != null
          ? DateTime.tryParse(json['accountCreatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownedProjectsCount': ownedProjectsCount,
    'sharedProjectsCount': sharedProjectsCount,
    'totalProjectsCount': totalProjectsCount,
    'createdBoardsCount': createdBoardsCount,
    'totalBoardsCount': totalBoardsCount,
    'accountCreatedAt': accountCreatedAt?.toIso8601String(),
  };
}
