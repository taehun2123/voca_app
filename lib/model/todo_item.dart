// lib/model/todo_item.dart

class TodoItem {
  final int? id; // SQLite 데이터베이스 ID (null이면 아직 저장 안됨)
  final String title; // 할 일 제목
  final DateTime dueDate; // 목표일
  late final bool isCompleted; // 완료 여부
  final DateTime createdAt; // 생성일

  TodoItem({
    this.id,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // SQLite 저장을 위한 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // SQLite에서 불러올 때 사용하는 팩토리 메서드
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      title: map['title'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // 일부 필드만 수정하여 새 인스턴스 생성
  TodoItem copyWith({
    int? id,
    String? title,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}