import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome 사용을 위한 import 추가
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vocabulary_app/services/ad_service.dart';
import 'package:vocabulary_app/services/db_service.dart';
import 'package:vocabulary_app/services/purchase_service.dart';
import 'package:vocabulary_app/services/remote_config_service.dart';
import 'package:vocabulary_app/services/tracking_permission_service.dart';
import 'package:vocabulary_app/theme/app_themes.dart';
import 'package:vocabulary_app/theme/theme_provider.dart';
import 'screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 방향 설정 - 세로 모드만 허용하여 오버플로우 문제 방지
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 데이터베이스 서비스 초기화
  final dbService = DBService();
  // 구매 서비스 초기화
  final purchaseService = PurchaseService();
  // 광고 서비스 초기화
  final adService = AdService();
    // ATT 권한 요청 서비스 초기화
  final trackingPermissionService = TrackingPermissionService();

  try {
    print('앱 시작: 데이터베이스 초기화 중...');

    // iOS에서 ATT 권한 요청 (앱 초기화 시점에 바로 요청)
    await trackingPermissionService.requestTrackingPermission();

    // 데이터베이스 접근 및 기본 쿼리 실행해보기
    final db = await dbService.database;
    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('데이터베이스 테이블 목록: ${tables.map((t) => t['name']).join(', ')}');

    // 단어 테이블 쿼리
    final wordCount =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM words"));
    print('단어 테이블 초기 레코드 수: ${wordCount ?? 0}');

    // 단어장 테이블 쿼리
    final dayCount = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM day_collections"));
    print('단어장 테이블 초기 레코드 수: ${dayCount ?? 0}');

    // day별 단어 수 쿼리
    final dayQuery = await db
        .rawQuery('SELECT day, COUNT(*) as count FROM words GROUP BY day');
    print('DAY별 단어 수:');
    for (var row in dayQuery) {
      final day = row['day'] ?? '없음';
      final count = row['count'];
      print('- $day: $count개');
    }

    // 구매 서비스 초기화
    await purchaseService.initialize();

    // Firebase 초기화
    await Firebase.initializeApp();

    // FirebaseAuth 초기화 (Google Drive API 인증에 사용)
    await FirebaseAuth.instance.setLanguageCode('ko'); // 언어 설정
    print('Firebase 및 Auth 초기화 완료');

    // Remote Config 초기화
    await RemoteConfigService().initialize();
    // 광고 서비스 초기화 (추가)
    await adService.initialize();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('앱 초기화 중 오류: $e');
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 테마 상태 프로바이더에서 현재 테마 모드 가져오기
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '찍어보카',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomePage(),
        );
      },
    );
  }
}
