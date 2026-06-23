import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/message.dart';
import '../models/secret.dart';
import '../models/user.dart';
import '../models/device.dart';

class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int skip;
  final int limit;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
  });

  bool get hasMore => skip + items.length < total;
}

class ApiService {
  final String baseUrl;
  final String? token;

  ApiService({required this.baseUrl, this.token});

  Map<String, String> get headers {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept-Charset': 'utf-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(
    String usernameOrEmail,
    String password,
  ) async {
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
    return _handleResponse(response);
  }

  Future<PaginatedResponse<Message>> getMessages({int skip = 0, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/messages?skip=$skip&limit=$limit'),
      headers: headers,
    );
    final data = _handleResponse(response);

    // Handle both new format (with pagination) and old format (list)
    if (data is List) {
      // Old format: just a list of messages
      final items = data.map((item) => Message.fromJson(item)).toList();
      return PaginatedResponse<Message>(
        items: items,
        total: items.length,
        skip: skip,
        limit: limit,
      );
    } else if (data is Map<String, dynamic>) {
      // New format: paginated response
      final itemsData = data['items'] as List;
      final items = itemsData.map((item) => Message.fromJson(item)).toList();
      return PaginatedResponse<Message>(
        items: items,
        total: data['total'] as int? ?? items.length,
        skip: data['skip'] as int? ?? skip,
        limit: data['limit'] as int? ?? limit,
      );
    } else {
      throw Exception('Unexpected response format');
    }
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
    return _handleResponse(response);
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/logout'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/forgot-password'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(response);
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/reset-password'),
      headers: headers,
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );
    return _handleResponse(response);
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/change-password'),
      headers: headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return _handleResponse(response);
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

  Future<Map<String, dynamic>> verifyTwoFactor(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/verify'),
      headers: headers,
      body: jsonEncode({'code': code}),
    );
    return _handleResponse(response);
  }

  Future<void> disableTwoFactor(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/two-factor/disable'),
      headers: headers,
      body: jsonEncode({'password': password}),
    );
    return _handleResponse(response);
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

  Future<bool> getUserNotificationsSetting() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me/settings'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data['notifications_enabled'] ?? true;
  }

  Future<bool> updateUserNotificationsSetting(bool enabled) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me/settings'),
      headers: headers,
      body: jsonEncode({'notifications_enabled': enabled}),
    );
    final data = _handleResponse(response);
    return data['notifications_enabled'] ?? enabled;
  }

  Future<Map<String, dynamic>> loginWithTwoFactor(
    String usernameOrEmail,
    String password,
    String twoFactorCode,
  ) async {
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

  Future<Device> registerDevice({
    required String deviceType,
    required String? deviceToken,
    required String? deviceName,
    required String? pushVendor,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/devices'),
      headers: headers,
      body: jsonEncode({
        'device_type': deviceType,
        'device_token': deviceToken,
        'device_name': deviceName,
        'push_vendor': pushVendor,
      }),
    );
    final data = _handleResponse(response);
    return Device.fromJson(data);
  }

  Future<List<Device>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/devices'),
      headers: headers,
    );
    final data = _handleResponse(response) as List;
    return data.map((item) => Device.fromJson(item)).toList();
  }

  Future<void> deleteDevice(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/devices/$id'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final bodyBytes = response.bodyBytes;
      final decodedBody = utf8.decode(bodyBytes, allowMalformed: true);
      return jsonDecode(decodedBody);
    }

    // Parse error response body for a user-friendly message
    String errorMessage;
    try {
      final bodyBytes = response.bodyBytes;
      final decodedBody = utf8.decode(bodyBytes, allowMalformed: true);
      final errorData = jsonDecode(decodedBody);
      if (errorData is Map && errorData.containsKey('detail')) {
        errorMessage = errorData['detail'].toString();
      } else {
        errorMessage = 'HTTP error ${response.statusCode}';
      }
    } catch (_) {
      errorMessage = 'HTTP error ${response.statusCode}';
    }
    throw Exception(errorMessage);
  }
}
