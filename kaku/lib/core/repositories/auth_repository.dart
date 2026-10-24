import 'dart:convert';
import '../models/user_model.dart';
import '../network/api_client.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'displayName': (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : name.trim(),
    };

    final response = await _api.post('/api/v1/auth/register', body: body);
    if (response is Map<String, dynamic>) {
      final token = response['token'] as String?;
      await _api.setToken(token);

      final userData = response['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);
      _currentUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Unexpected response from registration server');
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    final response = await _api.post('/api/v1/auth/login', body: body);
    if (response is Map<String, dynamic>) {
      final token = response['token'] as String?;
      await _api.setToken(token);

      final userData = response['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);
      _currentUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Unexpected response from login server');
  }

  Future<UserModel> getMe() async {
    final response = await _api.get('/api/v1/me');
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      _currentUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to retrieve user profile');
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
      _currentUser = user;
      await _api.setCachedUserJson(jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to update profile');
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

  Future<void> logout() async {
    _currentUser = null;
    await _api.clearAuth();
  }

  Future<UserModel?> checkAuthStatus() async {
    if (!_api.isAuthenticated) {
      return null;
    }
    try {
      final user = await getMe();
      return user;
    } catch (_) {
      final cachedJson = await _api.getCachedUserJson();
      if (cachedJson != null) {
        try {
          _currentUser = UserModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
          return _currentUser;
        } catch (_) {}
      }
      await logout();
      return null;
    }
  }
}
