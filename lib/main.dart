import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'services/api_key_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive 데이터베이스 초기화
  await Hive.initFlutter();
  await Hive.openBox('wordBox');
  await Hive.openBox('dayCollectionBox');
  await Hive.openBox('apiKeyBox');
  
  // API 키 서비스 초기화
  final apiKeyService = ApiKeyService();
  await apiKeyService.init();
  
  runApp(const MyApp());
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