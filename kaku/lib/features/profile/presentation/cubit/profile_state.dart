import '../../../../core/models/recent_board_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/user_preferences_model.dart';
import '../../../../core/models/user_stats_model.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final UserModel? user;
  final UserStatsModel? stats;
  final List<RecentBoardModel> recentBoards;
  final UserPreferencesModel preferences;
  final bool isSavingProfile;
  final bool isSavingPreferences;
  final bool isChangingPassword;
  final bool isChangingEmail;
  final bool isUploadingAvatar;
  final bool isDeletingAccount;
  final String? bannerMessage;
  final bool isBannerError;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.stats,
    this.recentBoards = const [],
    this.preferences = const UserPreferencesModel(),
    this.isSavingProfile = false,
    this.isSavingPreferences = false,
    this.isChangingPassword = false,
    this.isChangingEmail = false,
    this.isUploadingAvatar = false,
    this.isDeletingAccount = false,
    this.bannerMessage,
    this.isBannerError = false,
    this.errorMessage,
  });

  bool get isLoading => status == ProfileStatus.loading;
  bool get isLoaded => status == ProfileStatus.loaded;

  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    UserStatsModel? stats,
    List<RecentBoardModel>? recentBoards,
    UserPreferencesModel? preferences,
    bool? isSavingProfile,
    bool? isSavingPreferences,
    bool? isChangingPassword,
    bool? isChangingEmail,
    bool? isUploadingAvatar,
    bool? isDeletingAccount,
    String? bannerMessage,
    bool? isBannerError,
    String? errorMessage,
    bool clearBanner = false,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      stats: stats ?? this.stats,
      recentBoards: recentBoards ?? this.recentBoards,
      preferences: preferences ?? this.preferences,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingPreferences: isSavingPreferences ?? this.isSavingPreferences,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isChangingEmail: isChangingEmail ?? this.isChangingEmail,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      bannerMessage: clearBanner ? null : (bannerMessage ?? this.bannerMessage),
      isBannerError: clearBanner ? false : (isBannerError ?? this.isBannerError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
