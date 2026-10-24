import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/recent_board_model.dart';
import '../../../../core/models/user_preferences_model.dart';
import '../../../../core/models/user_stats_model.dart';
import '../../../../core/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository(),
        super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> loadProfile({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    }

    try {
      final user = await _repository.getProfile(includeStats: true);

      UserStatsModel? stats;
      try {
        stats = await _repository.getUserStats();
      } catch (_) {
        stats = state.stats;
      }

      List<RecentBoardModel> recentBoards = [];
      try {
        recentBoards = await _repository.getRecentBoards();
      } catch (_) {
        recentBoards = state.recentBoards;
      }

      UserPreferencesModel preferences = const UserPreferencesModel();
      try {
        preferences = await _repository.getPreferences();
      } catch (_) {
        preferences = UserPreferencesModel.fromJson(user.preferences);
      }

      emit(state.copyWith(
        status: ProfileStatus.loaded,
        user: user,
        stats: stats,
        recentBoards: recentBoards,
        preferences: preferences,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<bool> updateProfileDetails({
    required String name,
    required String displayName,
    required String bio,
  }) async {
    emit(state.copyWith(isSavingProfile: true, clearBanner: true));
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        displayName: displayName,
        bio: bio,
      );
      emit(state.copyWith(
        isSavingProfile: false,
        user: updatedUser,
        bannerMessage: 'Profile information updated successfully!',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSavingProfile: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> setAvatarUrl(String url) async {
    emit(state.copyWith(isUploadingAvatar: true, clearBanner: true));
    try {
      final updatedUser = await _repository.updateAvatarUrl(url);
      emit(state.copyWith(
        isUploadingAvatar: false,
        user: updatedUser,
        bannerMessage: 'Avatar updated successfully!',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isUploadingAvatar: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> uploadAvatarBytes(List<int> bytes, String filename) async {
    emit(state.copyWith(isUploadingAvatar: true, clearBanner: true));
    try {
      final updatedUser = await _repository.uploadAvatarBytes(bytes, filename);
      emit(state.copyWith(
        isUploadingAvatar: false,
        user: updatedUser,
        bannerMessage: 'Avatar uploaded and saved!',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isUploadingAvatar: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> removeAvatar() async {
    emit(state.copyWith(isUploadingAvatar: true, clearBanner: true));
    try {
      final updatedUser = await _repository.removeAvatar();
      emit(state.copyWith(
        isUploadingAvatar: false,
        user: updatedUser,
        bannerMessage: 'Avatar removed.',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isUploadingAvatar: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> updatePreferences(UserPreferencesModel newPrefs) async {
    emit(state.copyWith(isSavingPreferences: true, clearBanner: true));
    try {
      final updated = await _repository.updatePreferences(newPrefs);
      emit(state.copyWith(
        isSavingPreferences: false,
        preferences: updated,
        bannerMessage: 'Workspace preferences synchronized!',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSavingPreferences: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      emit(state.copyWith(
        bannerMessage: 'New password must be at least 8 characters long.',
        isBannerError: true,
      ));
      return false;
    }

    emit(state.copyWith(isChangingPassword: true, clearBanner: true));
    try {
      final msg = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(state.copyWith(
        isChangingPassword: false,
        bannerMessage: msg,
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isChangingPassword: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final cleanEmail = newEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      emit(state.copyWith(
        bannerMessage: 'Please enter a valid email address.',
        isBannerError: true,
      ));
      return false;
    }

    emit(state.copyWith(isChangingEmail: true, clearBanner: true));
    try {
      final updatedUser = await _repository.changeEmail(
        newEmail: cleanEmail,
        password: password,
      );
      emit(state.copyWith(
        isChangingEmail: false,
        user: updatedUser,
        bannerMessage: 'Email successfully updated to $cleanEmail',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isChangingEmail: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    emit(state.copyWith(isDeletingAccount: true, clearBanner: true));
    try {
      await _repository.deleteAccount(password: password);
      emit(state.copyWith(
        isDeletingAccount: false,
        bannerMessage: 'Account successfully deleted.',
        isBannerError: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isDeletingAccount: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      ));
      return false;
    }
  }

  void dismissBanner() {
    emit(state.copyWith(clearBanner: true));
  }
}
