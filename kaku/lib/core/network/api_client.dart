import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _tokenPrefKey = 'kaku_jwt_token';
  static const String _baseUrlPrefKey = 'kaku_base_url';
  static const String _userPrefKey = 'kaku_cached_user';

  String? _token;
  String _baseUrl = 'http://localhost:8080';

  static String get _defaultBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator default alias for localhost
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenPrefKey);
    final savedUrl = prefs.getString(_baseUrlPrefKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    } else {
      _baseUrl = _defaultBaseUrl;
    }
  }

  Future<void> setBaseUrl(String url) async {
    var formatted = url.trim();
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _baseUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, formatted);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenPrefKey, token);
    } else {
      await prefs.remove(_tokenPrefKey);
    }
  }

  Future<void> setCachedUserJson(String? userJson) async {
    final prefs = await SharedPreferences.getInstance();
    if (userJson != null) {
      await prefs.setString(_userPrefKey, userJson);
    } else {
      await prefs.remove(_userPrefKey);
    }
  }

  Future<String?> getCachedUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPrefKey);
  }

  Future<void> clearAuth() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
    await prefs.remove(_userPrefKey);
  }

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http.get(uri, headers: _buildHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at $_baseUrl. Ensure backend server is running.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at $_baseUrl. Ensure backend server is running.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.patch(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at $_baseUrl. Ensure backend server is running.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.put(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at $_baseUrl. Ensure backend server is running.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await http.delete(uri, headers: _buildHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at $_baseUrl. Ensure backend server is running.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final uri = _buildUri('/healthz');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String errorMessage = 'Request failed (${response.statusCode})';
    if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
      errorMessage = decoded['error'].toString();
    } else if (decoded is String && decoded.isNotEmpty) {
      errorMessage = decoded;
    }

    throw ApiException(errorMessage, response.statusCode);
  }
}
