import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _serverUrl;

  String? get token => _token;
  String? get serverUrl => _serverUrl;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _serverUrl = prefs.getString('server_url') ?? 'http://localhost:8000';
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  Future<void> saveServerUrl(String url) async {
    _serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    notifyListeners();
  }

  Future<void> login({
    required String token,
    required String serverUrl,
    String? username,
  }) async {
    _token = token;
    _serverUrl = serverUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('server_url', serverUrl);
    if (username != null) {
      await prefs.setString('username', username);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
}