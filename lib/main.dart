import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vocabulary_app/services/db_service.dart';
import 'screens/home_screen.dart';
import 'services/api_key_service.dart';

// main.dart 수정
// lib/main.dart의 main 함수 수정
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 데이터베이스 서비스 초기화
  final dbService = DBService();
  try {
    print('앱 시작: 데이터베이스 초기화 중...');
    
    // 데이터베이스 접근 및 기본 쿼리 실행해보기
    final db = await dbService.database;
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('데이터베이스 테이블 목록: ${tables.map((t) => t['name']).join(', ')}');
    
    // 단어 테이블 쿼리
    final wordCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM words")
    );
    print('단어 테이블 초기 레코드 수: ${wordCount ?? 0}');
    
    // 단어장 테이블 쿼리
    final dayCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM day_collections")
    );
    print('단어장 테이블 초기 레코드 수: ${dayCount ?? 0}');
    
    // day별 단어 수 쿼리
    final dayQuery = await db.rawQuery('SELECT day, COUNT(*) as count FROM words GROUP BY day');
    print('DAY별 단어 수:');
    for (var row in dayQuery) {
      final day = row['day'] ?? '없음';
      final count = row['count'];
      print('- $day: $count개');
    }
    
    // API 키 서비스 초기화
    final apiKeyService = ApiKeyService();
    await apiKeyService.init();
    
    runApp(const MyApp());
  } catch (e) {
    print('앱 초기화 중 오류: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '영어 단어 학습 앱',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}