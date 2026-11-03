import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'suraksha_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_prefKey);
      if (savedStr != null) {
        if (savedStr == 'light') {
          _themeMode = ThemeMode.light;
        } else if (savedStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (_) {
      // Keep default
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'system';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      await prefs.setString(_prefKey, val);
    } catch (_) {}
  }
}
