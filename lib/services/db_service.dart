import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/word_entry.dart';

class DBService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

Future<Database> _initDatabase() async {
  // 앱 문서 디렉토리 경로 얻기
  final documentsDirectory = await getApplicationDocumentsDirectory();
  String path = join(documentsDirectory.path, 'vocabulary.db');
  
  print('데이터베이스 경로: $path');
  
  // 해당 경로에 파일이 있는지 확인
  final file = File(path);
  final exists = await file.exists();
  print('데이터베이스 파일 존재 여부: $exists');
  
  // WAL 모드 설정 제거 (오류 발생)
  final db = await openDatabase(
    path,
    version: 1,
    onCreate: _createDatabase,
  );
  
  // 기본 동기화 설정만 사용
  await db.execute('PRAGMA synchronous = NORMAL');
  print('데이터베이스 동기화 설정 완료');
  
  return db;
}

  Future<void> _createDatabase(Database db, int version) async {
    print('데이터베이스 테이블 생성 시작');

    // 단어 테이블
    await db.execute('''
      CREATE TABLE words(
        word TEXT PRIMARY KEY,
        pronunciation TEXT,
        meaning TEXT NOT NULL,
        examples TEXT,
        commonPhrases TEXT,
        day TEXT,
        createdAt INTEGER,
        reviewCount INTEGER DEFAULT 0,
        isMemorized INTEGER DEFAULT 0
      )
    ''');

    // 단어장(DAY) 테이블
    await db.execute('''
      CREATE TABLE day_collections(
        day TEXT PRIMARY KEY,
        createdAt INTEGER,
        wordCount INTEGER DEFAULT 0
      )
    ''');

    print('데이터베이스 테이블 생성 완료');
  }

  // 단어 저장
  Future<void> saveWord(WordEntry word) async {
    final Database db = await database;

    try {
      // examples와 commonPhrases는 JSON 문자열로 변환
      await db.insert(
        'words',
        {
          'word': word.word,
          'pronunciation': word.pronunciation,
          'meaning': word.meaning,
          'examples': jsonEncode(word.examples),
          'commonPhrases': jsonEncode(word.commonPhrases),
          'day': word.day,
          'createdAt': word.createdAt.millisecondsSinceEpoch,
          'reviewCount': word.reviewCount,
          'isMemorized': word.isMemorized ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // 중복 시 교체
      );

      // 저장 후 즉시 확인
      final List<Map<String, dynamic>> maps = await db.query(
        'words',
        where: 'word = ?',
        whereArgs: [word.word],
      );

      print('단어 저장 직후 확인: ${maps.isNotEmpty ? "성공" : "실패"}');
      if (maps.isNotEmpty) {
        print('저장된 단어 데이터: ${maps[0]}');
      }
    } catch (e) {
      print('단어 저장 실패: ${word.word}, 오류: $e');
    }
  }

  // 여러 단어 저장
// 여러 단어 저장 함수 수정
// lib/services/db_service.dart의 saveWords 함수 수정
Future<void> saveWords(List<WordEntry> words) async {
  final Database db = await database;
  
  print('${words.length}개 단어 저장 시작');
  
  int successCount = 0;
  int failCount = 0;
  
  // 각 단어별로 상세 로그 출력
  for (var word in words) {
    try {
      print('단어 저장: "${word.word}", day: "${word.day ?? '없음'}"');
      
      await db.insert(
        'words',
        {
          'word': word.word,
          'pronunciation': word.pronunciation,
          'meaning': word.meaning,
          'examples': jsonEncode(word.examples),
          'commonPhrases': jsonEncode(word.commonPhrases),
          'day': word.day,
          'createdAt': word.createdAt.millisecondsSinceEpoch,
          'reviewCount': word.reviewCount,
          'isMemorized': word.isMemorized ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      successCount++;
    } catch (e) {
      failCount++;
      print('단어 저장 오류 (${word.word}): $e');
    }
  }
  
  // 저장 결과 출력
  print('단어 저장 결과: 성공 $successCount개, 실패 $failCount개');
  
  // 저장 후 단어 수 확인
  try {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM words'));
    print('저장 후 단어 테이블 레코드 수: $count');
    
    // day별 단어 수 출력
    final dayQuery = await db.rawQuery('SELECT day, COUNT(*) as count FROM words GROUP BY day');
    print('DAY별 단어 수:');
    for (var row in dayQuery) {
      final day = row['day'] ?? '없음';
      final count = row['count'];
      print('- $day: $count개');
    }
  } catch (e) {
    print('단어 수 확인 중 오류: $e');
  }
}

  // 단어 가져오기
  Future<WordEntry?> getWord(String wordText) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'word = ?',
      whereArgs: [wordText],
    );

    if (maps.isEmpty) return null;

    try {
      return WordEntry(
        word: maps[0]['word'] as String,
        pronunciation: maps[0]['pronunciation'] as String? ?? '',
        meaning: maps[0]['meaning'] as String,
        examples: List<String>.from(jsonDecode(maps[0]['examples'] as String)),
        commonPhrases:
            List<String>.from(jsonDecode(maps[0]['commonPhrases'] as String)),
        day: maps[0]['day'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(maps[0]['createdAt'] as int),
        reviewCount: maps[0]['reviewCount'] as int,
        isMemorized: (maps[0]['isMemorized'] as int) == 1,
      );
    } catch (e) {
      print('단어 파싱 오류: $e');
      return null;
    }
  }
  

// 모든 단어 가져오기 함수 수정
  Future<List<WordEntry>> getAllWords() async {
    final Database db = await database;

    // 먼저 단어 테이블이 존재하는지 확인
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='words'");
    if (tables.isEmpty) {
      print('단어 테이블이 존재하지 않음');
      return [];
    }

    // 단어 개수 확인
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM words'));
    print('단어 테이블 레코드 수: $count');

    if (count == 0) {
      print('단어 테이블에 데이터가 없음');
      return [];
    }

    // 모든 단어 가져오기
    final List<Map<String, dynamic>> maps = await db.query('words');
    print('쿼리 결과 개수: ${maps.length}');

    List<WordEntry> words = [];

    for (var map in maps) {
      try {
        words.add(WordEntry(
          word: map['word'] as String,
          pronunciation: map['pronunciation'] as String? ?? '',
          meaning: map['meaning'] as String,
          examples: List<String>.from(jsonDecode(map['examples'] as String)),
          commonPhrases:
              List<String>.from(jsonDecode(map['commonPhrases'] as String)),
          day: map['day'] as String?,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
          reviewCount: map['reviewCount'] as int,
          isMemorized: (map['isMemorized'] as int) == 1,
        ));
      } catch (e) {
        print('단어 파싱 오류 (${map['word']}): $e');
      }
    }

    print('총 ${words.length}개 단어 로드 완료');
    return words;
  }

  // DAY별 단어 가져오기
// lib/services/db_service.dart에 메서드 추가
Future<List<WordEntry>> getWordsByDay(String? day) async {
  final Database db = await database;
  
  List<Map<String, dynamic>> maps;
  if (day == null) {
    // day가 null인 단어들 조회
    maps = await db.query(
      'words',
      where: 'day IS NULL',
    );
    print('day가 null인 단어 조회: ${maps.length}개');
  } else {
    // 특정 day의 단어들 조회
    maps = await db.query(
      'words',
      where: 'day = ?',
      whereArgs: [day],
    );
    print('day가 "$day"인 단어 조회: ${maps.length}개');
  }
  
  List<WordEntry> words = [];
  
  for (var map in maps) {
    try {
      words.add(WordEntry(
        word: map['word'] as String,
        pronunciation: map['pronunciation'] as String? ?? '',
        meaning: map['meaning'] as String,
        examples: List<String>.from(jsonDecode(map['examples'] as String)),
        commonPhrases: List<String>.from(jsonDecode(map['commonPhrases'] as String)),
        day: map['day'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        reviewCount: map['reviewCount'] as int,
        isMemorized: (map['isMemorized'] as int) == 1,
      ));
    } catch (e) {
      print('단어 파싱 오류: $e');
    }
  }
  
  return words;
}

  // DAY 컬렉션 정보 저장
  Future<void> saveDayCollection(String day, int wordCount) async {
    final Database db = await database;

    await db.insert(
      'day_collections',
      {
        'day': day,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'wordCount': wordCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('단어장 정보 저장: $day ($wordCount단어)');
  }

  // 모든 DAY 정보 가져오기
  Future<Map<String, Map<String, dynamic>>> getAllDays() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('day_collections');

    Map<String, Map<String, dynamic>> result = {};

    for (var map in maps) {
      String day = map['day'] as String;
      result[day] = {
        'createdAt': map['createdAt'] as int,
        'wordCount': map['wordCount'] as int,
      };
    }

    print('${result.keys.length}개 DAY 정보 로드 완료');
    return result;
  }

  // 단어 삭제
// lib/services/db_service.dart의 deleteWord 함수 수정
Future<void> deleteWord(String wordText) async {
  final Database db = await database;
  
  try {
    // 삭제 전 단어 확인
    final word = await getWord(wordText);
    if (word == null) {
      print('삭제할 단어를 찾을 수 없음: $wordText');
      return;
    }
    
    print('단어 삭제: $wordText (day: ${word.day ?? 'null'})');
    
    // 단어 삭제
    final count = await db.delete(
      'words',
      where: 'word = ?',
      whereArgs: [wordText],
    );
    
    print('단어 삭제 결과: ${count > 0 ? "성공" : "실패"} ($wordText)');
  } catch (e) {
    print('단어 삭제 중 오류: $e');
    throw e;
  }
}

  // DAY 삭제
// lib/services/db_service.dart의 deleteDay 함수 수정
Future<void> deleteDay(String day) async {
  final Database db = await database;
  
  try {
    // 트랜잭션 사용하여 모든 작업이 성공하거나 실패하도록 보장
    await db.transaction((txn) async {
      // 1. 먼저 삭제할 단어의 개수 확인 (디버깅 용도)
      final List<Map<String, dynamic>> wordCount = await txn.rawQuery(
        'SELECT COUNT(*) as count FROM words WHERE day = ?',
        [day]
      );
      final int count = Sqflite.firstIntValue(wordCount) ?? 0;
      print('단어장 "$day" 삭제: $count개 단어 삭제 예정');
      
      // 2. 해당 DAY에 속한 단어들 삭제
      final int deletedWordsCount = await txn.delete(
        'words',
        where: 'day = ?',
        whereArgs: [day],
      );
      print('단어장 "$day" 삭제: $deletedWordsCount개 단어 삭제됨');
      
      // 3. DAY 컬렉션 정보 삭제
      final int deletedDayCount = await txn.delete(
        'day_collections',
        where: 'day = ?',
        whereArgs: [day],
      );
      print('단어장 "$day" 삭제: 컬렉션 정보 ${deletedDayCount > 0 ? "삭제됨" : "삭제 실패"}');
      
      // 4. 삭제 후 확인 쿼리 (디버깅 용도)
      final List<Map<String, dynamic>> remainingCheck = await txn.rawQuery(
        'SELECT COUNT(*) as count FROM words WHERE day = ?',
        [day]
      );
      final int remaining = Sqflite.firstIntValue(remainingCheck) ?? 0;
      print('단어장 "$day" 삭제 후 남은 단어: $remaining개');
    });
    
    print('단어장 "$day" 삭제 완료');
  } catch (e) {
    print('단어장 삭제 중 오류: $e');
    throw e; // 오류를 상위로 전달하여 UI에서 처리할 수 있도록 함
  }
}

  // 암기 상태 업데이트
  Future<void> updateMemorizedStatus(String wordText, bool isMemorized) async {
    final Database db = await database;

    await db.update(
      'words',
      {'isMemorized': isMemorized ? 1 : 0},
      where: 'word = ?',
      whereArgs: [wordText],
    );

    print('암기 상태 업데이트: $wordText (${isMemorized ? '암기완료' : '미암기'})');
  }

  // 복습 횟수 증가
  Future<void> incrementReviewCount(String wordText) async {
    final Database db = await database;

    // 현재 복습 횟수 가져오기
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      columns: ['reviewCount'],
      where: 'word = ?',
      whereArgs: [wordText],
    );

    if (maps.isNotEmpty) {
      int currentCount = maps[0]['reviewCount'] as int;

      await db.update(
        'words',
        {'reviewCount': currentCount + 1},
        where: 'word = ?',
        whereArgs: [wordText],
      );

      print('복습 횟수 증가: $wordText (${currentCount + 1}회)');
    }
  }

  // 데이터베이스 유효성 검사
  Future<void> validateDatabase() async {
    try {
      final Database db = await database;

      // 테이블 존재 여부 확인
      final List<Map<String, dynamic>> tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table';");

      print('===== 데이터베이스 유효성 검사 =====');
      print('존재하는 테이블: ${tables.map((t) => t['name']).join(', ')}');

      // 단어 테이블 레코드 수 확인
      final wordCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM words'));
      print('단어 테이블 레코드 수: $wordCount');

      // 단어장 테이블 레코드 수 확인
      final dayCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM day_collections'));
      print('단어장 테이블 레코드 수: $dayCount');

      // 샘플 데이터 확인
      if (wordCount! > 0) {
        final sample = await db.query('words', limit: 1);
        print('단어 샘플: ${sample.first}');
      }

      print('===== 검사 완료 =====');
    } catch (e) {
      print('데이터베이스 검사 중 오류: $e');
    }
  }

  // DBService 클래스에 메서드 추가
  Future<void> ensureDatabaseSync() async {
    final db = await database;
    await db.execute('PRAGMA synchronous = FULL');
    await db.execute('PRAGMA journal_mode = WAL');
    print('데이터베이스 동기화 설정 완료');
  }

  // lib/services/db_service.dart에 메서드 추가
Future<void> deleteNullDayWords() async {
  final Database db = await database;
  
  try {
    // 삭제할 단어 수 확인
    final List<Map<String, dynamic>> countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE day IS NULL'
    );
    final int count = Sqflite.firstIntValue(countResult) ?? 0;
    print('day가 null인 단어 삭제 시작: $count개');
    
    // 단어 삭제
    final deletedCount = await db.delete(
      'words',
      where: 'day IS NULL'
    );
    
    print('day가 null인 단어 삭제 완료: $deletedCount개 단어 삭제됨');
  } catch (e) {
    print('day가 null인 단어 삭제 중 오류: $e');
    throw e;
  }
}
}
