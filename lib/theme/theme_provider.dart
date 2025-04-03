import 'package:flutter/material.dart';
import 'theme_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // 테마 상태 저장
  bool _isDarkMode = false;
  ThemePreferences _preferences = ThemePreferences();

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // 저장된 테마 설정 로드
  _loadThemeFromPrefs() async {
    _isDarkMode = await _preferences.getTheme();
    notifyListeners();
  }

  // 테마 변경
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _preferences.setTheme(_isDarkMode);
    notifyListeners();
  }

  // 특정 테마 설정
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _preferences.setTheme(_isDarkMode);
    notifyListeners();
  }
}