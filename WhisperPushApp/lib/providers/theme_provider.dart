
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? true;
      AppTheme.setThemeMode(_isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    AppTheme.setThemeMode(_isDarkMode);
    notifyListeners();
    await _saveTheme();
  }

  Future<void> setThemeMode(bool isDark) async {
    _isDarkMode = isDark;
    AppTheme.setThemeMode(_isDarkMode);
    notifyListeners();
    await _saveTheme();
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }
}
