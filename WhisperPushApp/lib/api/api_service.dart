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

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    throw Exception('HTTP error ${response.statusCode}: ${response.body}');
  }
}