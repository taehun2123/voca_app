import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const PREF_KEY = "theme_preference";

  // 테마 설정 저장
  setTheme(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(PREF_KEY, isDarkMode);
  }

  // 저장된 테마 설정 불러오기
  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_KEY) ?? false; // 기본값은 라이트 모드
  }
}