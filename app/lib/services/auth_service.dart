import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://manga-api.intern.phudevelopement.xyz';
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }

  /// Save token and user data
  Future<void> saveAuthData(String token, Map<String, dynamic> user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  /// Clear auth data
  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveAuthData(data['token'], data['user']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  /// Register
  Future<Map<String, dynamic>> register(
    String email,
    String name,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveAuthData(data['token'], data['user']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  /// Get current user info from API
  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user info');
    }
  }

  /// Logout
  Future<void> logout() async {
    await clearAuthData();
  }

  /// Update user settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'settings': settings}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update settings');
    }
  }
}
