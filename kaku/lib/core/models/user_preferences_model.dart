class UserPreferencesModel {
  final String theme; // 'system', 'dark', 'light'
  final bool grid;
  final bool snapToGrid;
  final bool emailNotifications;

  const UserPreferencesModel({
    this.theme = 'system',
    this.grid = true,
    this.snapToGrid = false,
    this.emailNotifications = true,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPreferencesModel();
    return UserPreferencesModel(
      theme: json['theme'] as String? ?? 'system',
      grid: json['grid'] as bool? ?? true,
      snapToGrid: json['snapToGrid'] as bool? ?? false,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'grid': grid,
    'snapToGrid': snapToGrid,
    'emailNotifications': emailNotifications,
  };

  UserPreferencesModel copyWith({
    String? theme,
    bool? grid,
    bool? snapToGrid,
    bool? emailNotifications,
  }) {
    return UserPreferencesModel(
      theme: theme ?? this.theme,
      grid: grid ?? this.grid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }
}
