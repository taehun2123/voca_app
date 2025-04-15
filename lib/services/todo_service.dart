// lib/services/todo_service.dart

import 'package:sqflite/sqflite.dart';
import '../model/todo_item.dart';
import 'db_service.dart';

class TodoService {
  final DBService _dbService = DBService();

  // 테이블 초기화 (기존 DBService와 함께 작동하도록 설정)
  Future<void> initTable() async {
    final db = await _dbService.database;
    
    // 테이블이 존재하는지 확인
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='todos'"
    );
    
    if (tables.isEmpty) {
      // 테이블이 없으면 생성
      await db.execute('''
        CREATE TABLE todos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          dueDate INTEGER NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
        )
      ''');
      print('TodoService: todos 테이블 생성됨');
    } else {
      print('TodoService: todos 테이블이 이미 존재함');
    }
  }

  // 할 일 추가
  Future<TodoItem> addTodo(TodoItem todo) async {
    final db = await _dbService.database;
    
    // id 필드는 자동 증가이므로 제외하고 데이터 삽입
    final id = await db.insert(
      'todos',
      todo.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // 새로 생성된 id로 TodoItem 반환
    return todo.copyWith(id: id);
  }

  // 할 일 업데이트
  Future<int> updateTodo(TodoItem todo) async {
    final db = await _dbService.database;
    
    if (todo.id == null) {
      throw Exception('ID가 없는 할 일은 업데이트할 수 없습니다');
    }
    
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // 할 일 삭제
  Future<int> deleteTodo(int id) async {
    final db = await _dbService.database;
    
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 완료 상태 토글
  Future<int> toggleCompleted(int id, bool isCompleted) async {
    final db = await _dbService.database;
    
    return await db.update(
      'todos',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 특정 날짜의 할 일 가져오기
  Future<List<TodoItem>> getTodosByDate(DateTime date) async {
    final db = await _dbService.database;
    
    // 날짜 범위 계산 (선택한 날짜의 시작과 끝)
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final startTimestamp = startOfDay.millisecondsSinceEpoch;
    final endTimestamp = endOfDay.millisecondsSinceEpoch;
    
    final results = await db.query(
      'todos',
      where: 'dueDate >= ? AND dueDate <= ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: 'isCompleted, dueDate ASC', // 완료되지 않은 항목 먼저, 그다음 날짜순
    );
    
    return results.map((map) => TodoItem.fromMap(map)).toList();
  }

  // 모든 할 일 가져오기
  Future<List<TodoItem>> getAllTodos() async {
    final db = await _dbService.database;
    
    final results = await db.query(
      'todos',
      orderBy: 'dueDate ASC, isCompleted',
    );
    
    return results.map((map) => TodoItem.fromMap(map)).toList();
  }

  // 미완료 할 일 개수 가져오기
  Future<int> getIncompleteCount() async {
    final db = await _dbService.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos WHERE isCompleted = 0'
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 날짜별 할 일 개수 가져오기 (캘린더에 표시할 이벤트 개수)
  Future<Map<DateTime, int>> getTodoCountsByDate(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    
    final startTimestamp = start.millisecondsSinceEpoch;
    final endTimestamp = end.millisecondsSinceEpoch;
    
    final results = await db.rawQuery('''
      SELECT
        CAST((dueDate / 86400000) AS INTEGER) AS day,
        COUNT(*) AS count
      FROM todos
      WHERE dueDate >= ? AND dueDate <= ?
      GROUP BY day
    ''', [startTimestamp, endTimestamp]);
    
    Map<DateTime, int> countMap = {};
    
    for (var row in results) {
      final dayTimestamp = (row['day'] as int) * 86400000; // 일(day) 타임스탬프를 밀리초로 변환
      final date = DateTime.fromMillisecondsSinceEpoch(dayTimestamp);
      final dateWithoutTime = DateTime(date.year, date.month, date.day);
      countMap[dateWithoutTime] = row['count'] as int;
    }
    
    return countMap;
  }
  
  // 할 일이 있는 날짜 목록 가져오기
  Future<List<DateTime>> getTodoDates() async {
    final db = await _dbService.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT
        CAST((dueDate / 86400000) AS INTEGER) AS day
      FROM todos
      ORDER BY day ASC
    ''');
    
    return results.map((row) {
      final dayTimestamp = (row['day'] as int) * 86400000;
      final date = DateTime.fromMillisecondsSinceEpoch(dayTimestamp);
      return DateTime(date.year, date.month, date.day);
    }).toList();
  }
}