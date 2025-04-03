import 'package:flutter/material.dart';

class AppThemes {
  // 라이트 모드 테마
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Pretendard',
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black54),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey.shade600,
      indicatorColor: Colors.blue,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      color: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.green,
      secondary: Colors.blue,
      surface: Colors.white,
      background: Colors.grey.shade50,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
    ),
  );

  // 다크 모드 테마
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Color(0xFF121212), // 다크 모드 배경색
    fontFamily: 'Pretendard',
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF1E1E1E), // 다크 모드 앱바 색상
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    cardTheme: CardTheme(
      color: Color(0xFF2C2C2C), // 다크 모드 카드 색상
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.lightBlue.shade300, // 다크 모드에서 더 밝은 파란색
      unselectedLabelColor: Colors.grey.shade400,
      indicatorColor: Colors.lightBlue.shade300,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      color: Color(0xFF1E1E1E), // 다크 모드 하단 앱바 색상
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.lightBlue.shade300,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.green.shade700, // 다크 모드 버튼 색상
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.green.shade200), // 다크 모드 버튼 테두리 색상
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundColor: Colors.green.shade200, // 다크 모드 텍스트 버튼 색상
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      fillColor: Color(0xFF2C2C2C), // 다크 모드 입력 필드 배경색
      filled: true,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.green.shade600,
      secondary: Colors.lightBlue.shade300,
      surface: Color(0xFF2C2C2C),
      background: Color(0xFF121212),
      error: Colors.red.shade300,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
    ),
    // 다크 모드 진입 애니메이션을 부드럽게
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}