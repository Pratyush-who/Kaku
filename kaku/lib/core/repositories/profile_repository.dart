import 'dart:convert';
import '../models/recent_board_model.dart';
import '../models/user_model.dart';
import '../models/user_preferences_model.dart';
import '../models/user_stats_model.dart';
import '../network/api_client.dart';

class ProfileRepository {
  final ApiClient _api = ApiClient.instance;

  UserModel? _cachedUser;
  UserModel? get currentUser => _cachedUser;

  Future<UserModel> getProfile({bool includeStats = false}) async {
    final path = includeStats ? '/api/v1/me?include=stats' : '/api/v1/me';
    final response = await _api.get(path);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('user')) {
        final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
        _cachedUser = user;
        await _api.setCachedUserJson(jsonEncode(user.toJson()));
        return user;
      }
      final user = UserModel.fromJson(response);
      _cachedUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to retrieve user profile');
  }

  Future<UserStatsModel> getUserStats() async {
    final response = await _api.get('/api/v1/me/stats');
    if (response is Map<String, dynamic>) {
      return UserStatsModel.fromJson(response);
    }
    throw ApiException('Failed to load user statistics');
  }

  Future<List<RecentBoardModel>> getRecentBoards({int limit = 10, int offset = 0}) async {
    final response = await _api.get('/api/v1/me/recent-boards', queryParams: {
      'limit': limit,
      'offset': offset,
    });
    if (response is Map<String, dynamic> && response.containsKey('boards')) {
      final list = response['boards'] as List<dynamic>? ?? [];
      return list
          .map((item) => RecentBoardModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<UserPreferencesModel> getPreferences() async {
    final response = await _api.get('/api/v1/me/preferences');
    if (response is Map<String, dynamic>) {
      return UserPreferencesModel.fromJson(response);
    }
    return const UserPreferencesModel();
  }

  Future<UserPreferencesModel> updatePreferences(UserPreferencesModel prefs) async {
    final response = await _api.patch('/api/v1/me/preferences', body: prefs.toJson());
    if (response is Map<String, dynamic>) {
      final updated = UserPreferencesModel.fromJson(response);
      if (_cachedUser != null) {
        _cachedUser = _cachedUser!.copyWith(preferences: updated.toJson());
        await _api.setCachedUserJson(jsonEncode(_cachedUser!.toJson()));
      }
      return updated;
    }
    return prefs;
  }

  Future<UserModel> updateProfile({
    String? name,
    String? displayName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (displayName != null) body['displayName'] = displayName.trim();
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl.trim();
    if (bio != null) body['bio'] = bio.trim();
    if (preferences != null) body['preferences'] = preferences;

    final response = await _api.patch('/api/v1/me', body: body);
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      _cachedUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to update profile');
  }

  Future<UserModel> updateAvatarUrl(String avatarUrl) async {
    final response = await _api.post('/api/v1/me/avatar', body: {'avatarUrl': avatarUrl.trim()});
    if (response is Map<String, dynamic> && response.containsKey('user')) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _cachedUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to update avatar URL');
  }

  Future<UserModel> uploadAvatarBytes(List<int> bytes, String filename) async {
    final response = await _api.uploadMultipart(
      '/api/v1/me/avatar',
      bytes: bytes,
      filename: filename,
      fieldName: 'avatar',
    );
    if (response is Map<String, dynamic> && response.containsKey('user')) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _cachedUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to upload avatar image');
  }

  Future<UserModel> removeAvatar() async {
    final response = await _api.delete('/api/v1/me/avatar');
    if (response is Map<String, dynamic> && response.containsKey('user')) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _cachedUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to remove avatar');
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    final response = await _api.post('/api/v1/me/password', body: body);
    if (response is Map<String, dynamic> && response.containsKey('message')) {
      return response['message'] as String;
    }
    return 'Password updated successfully';
  }

  Future<UserModel> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final body = {
      'newEmail': newEmail.trim().toLowerCase(),
      'password': password,
    };
    final response = await _api.post('/api/v1/me/email', body: body);
    if (response is Map<String, dynamic>) {
      final token = response['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _api.setToken(token);
      }
      final userData = response['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);
      _cachedUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to update email');
  }

  Future<void> deleteAccount({required String password}) async {
    await _api.delete('/api/v1/me', body: {'password': password});
    _cachedUser = null;
    await _api.clearAuth();
  }
}
