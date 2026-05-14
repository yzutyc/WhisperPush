import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/message.dart';
import '../models/secret.dart';

class ApiService {
  final String baseUrl;
  final String? token;

  ApiService({required this.baseUrl, this.token});

  Map<String, String> get headers {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: headers,
      body: jsonEncode({
        'username_or_email': usernameOrEmail,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<User> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  Future<SecretWithKey> createSecret({String? name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/secrets'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );
    final data = _handleResponse(response);
    return SecretWithKey.fromJson(data);
  }

  Future<List<Secret>> getSecrets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/secrets'),
      headers: headers,
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => Secret.fromJson(item)).toList();
  }

  Future<void> deleteSecret(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/secrets/$id'),
      headers: headers,
    );
    _handleResponse(response);
  }

  Future<List<Message>> getMessages({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/messages?skip=$skip&limit=$limit'),
      headers: headers,
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => Message.fromJson(item)).toList();
  }

  Future<Message> getMessage(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/messages/$id'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return Message.fromJson(data);
  }

  Future<Message> markMessageRead(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/messages/$id/read'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return Message.fromJson(data);
  }

  Future<Message> markMessageUnread(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/messages/$id/unread'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return Message.fromJson(data);
  }

  Future<void> deleteMessage(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/messages/$id'),
      headers: headers,
    );
    _handleResponse(response);
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/logout'),
      headers: headers,
    );
    _handleResponse(response);
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/forgot-password'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );
    _handleResponse(response);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/change-password'),
      headers: headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> getTwoFactorInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/auth/two-factor'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> enableTwoFactor() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/enable'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<void> verifyTwoFactor(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/verify'),
      headers: headers,
      body: jsonEncode({'code': code}),
    );
    _handleResponse(response);
  }

  Future<void> disableTwoFactor(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/disable'),
      headers: headers,
      body: jsonEncode({'password': password}),
    );
    _handleResponse(response);
  }

  Future<List<String>> getRecoveryCodes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/recovery-codes'),
      headers: headers,
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => item.toString()).toList();
  }

  Future<List<String>> regenerateRecoveryCodes() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/recovery-codes/regenerate'),
      headers: headers,
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => item.toString()).toList();
  }

  Future<Map<String, dynamic>> loginWithTwoFactor(String usernameOrEmail, String password, String twoFactorCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: headers,
      body: jsonEncode({
        'username_or_email': usernameOrEmail,
        'password': password,
        'two_factor_code': twoFactorCode,
      }),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    throw Exception('HTTP error ${response.statusCode}: ${response.body}');
  }
}