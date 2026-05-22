import 'package:shared_preferences/shared_preferences.dart';

class ServerCache {
  static const String _keyServerUrls = 'server_urls';
  static const String _keyCurrentServer = 'current_server';
  static const int _maxCacheSize = 5;

  static Future<List<String>> getHistoryUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList(_keyServerUrls) ?? [];
    return urls;
  }

  static Future<void> addUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final urls = await getHistoryUrls();

    urls.remove(url);
    urls.insert(0, url);

    if (urls.length > _maxCacheSize) {
      urls.removeLast();
    }

    await prefs.setStringList(_keyServerUrls, urls);
  }

  static Future<String?> getCurrentServer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentServer);
  }

  static Future<void> setCurrentServer(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentServer, url);
    await addUrl(url);
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrls);
    await prefs.remove(_keyCurrentServer);
  }
}
