// lib/services/api_key_service.dart 수정

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ApiKeyService {
  static const String _openaiApiKeyKey = 'openai_api_key';
  static Database? _database;
  
  // 데이터베이스 가져오기
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }
  
  // 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'api_keys.db');
    print('API 키 데이터베이스 경로: $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }
  
  // 테이블 생성
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE api_keys(
        key_name TEXT PRIMARY KEY,
        key_value TEXT NOT NULL
      )
    ''');
    
    print('API 키 테이블 생성 완료');
  }
  
  // 초기화
  Future<void> init() async {
    await database;
    print('ApiKeyService 초기화 완료');
  }
  
  // OpenAI API 키 저장
  Future<void> saveOpenAIApiKey(String apiKey) async {
    final db = await database;
    
    await db.insert(
      'api_keys',
      {
        'key_name': _openaiApiKeyKey,
        'key_value': apiKey,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('OpenAI API 키 저장 완료');
  }
  
  // OpenAI API 키 가져오기
  Future<String?> getOpenAIApiKey() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'api_keys',
      columns: ['key_value'],
      where: 'key_name = ?',
      whereArgs: [_openaiApiKeyKey],
    );
    
    if (maps.isNotEmpty) {
      return maps[0]['key_value'] as String;
    }
    
    return null;
  }
  
  // API 키가 설정되었는지 확인
  Future<bool> hasOpenAIApiKey() async {
    final apiKey = await getOpenAIApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  // API 키 삭제
  Future<void> deleteOpenAIApiKey() async {
    final db = await database;
    
    await db.delete(
      'api_keys',
      where: 'key_name = ?',
      whereArgs: [_openaiApiKeyKey],
    );
    
    print('OpenAI API 키 삭제 완료');
  }
}