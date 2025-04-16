import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../model/word_entry.dart';
import '../model/todo_item.dart';
import '../services/todo_service.dart';

class HomeTab extends StatefulWidget {
  final Map<String, List<WordEntry>> dayCollections;
  final String currentDay;
  final Function(String) onDayChanged;
  final Function() navigateToWordTab;
  final Function() onAddWord;

  const HomeTab({
    Key? key,
    required this.dayCollections,
    required this.currentDay,
    required this.onDayChanged,
    required this.navigateToWordTab,
    required this.onAddWord,
  }) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TodoService _todoService = TodoService();
  // 진행 중인 항목과 완료된 항목을 분리
  List<TodoItem> _activeTodos = [];
  List<TodoItem> _completedTodos = [];
  // 캘린더 관련 변수
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 할 일 목록
  List<TodoItem> _todoItems = [];
  Map<DateTime, int> _eventCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeAndLoadData();
  }

  // 데이터베이스 초기화 및 데이터 로드
  Future<void> _initializeAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 테이블 초기화
      await _todoService.initTable();

      // 오늘 날짜의 할 일 로드
      _loadTodosForSelectedDate();

      // 이벤트 개수 로드 (캘린더 마커용)
      await _loadEventCounts();
    } catch (e) {
      print('할 일 데이터 로드 중 오류: $e');
      // 오류 발생시 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로드 중 오류가 발생했습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// 데이터 로드 시 분류
  void _loadTodosForSelectedDate() async {
    if (_selectedDay == null) return;

    final todos = await _todoService.getTodosByDate(_selectedDay!);

    if (mounted) {
      setState(() {
        _todoItems = todos; // 전체 목록 유지
        _activeTodos = todos.where((item) => !item.isCompleted).toList();
        _completedTodos = todos.where((item) => item.isCompleted).toList();
      });
    }
  }

  // 캘린더 이벤트 개수 로드
  Future<void> _loadEventCounts() async {
    // 현재 보이는 달의 시작과 끝 날짜 계산
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final countMap = await _todoService.getTodoCountsByDate(firstDay, lastDay);

    if (mounted) {
      setState(() {
        _eventCounts = countMap;
      });
    }
  }

  // 할 일 추가 다이얼로그
  Future<void> _showAddTodoDialog() async {
    final TextEditingController titleController = TextEditingController();
    final DateTime initialDate = _selectedDay ?? DateTime.now();
    DateTime selectedDate = initialDate;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('새 학습 목표 추가'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '목표 내용',
                  hintText: '예: 단어 50개 암기하기',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.amber.shade300
                          : Colors.amber.shade800,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 날짜 선택
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade800,
                  ),
                  SizedBox(width: 8),
                  Text('목표일: '),
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now()
                            .subtract(Duration(days: 30)), // 과거 일정도 입력 가능
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: isDarkMode
                                    ? Colors.amber.shade700
                                    : Colors.amber.shade600,
                                onPrimary: Colors.white,
                                surface: isDarkMode
                                    ? Color(0xFF2A2A2A)
                                    : Colors.white,
                                onSurface:
                                    isDarkMode ? Colors.white : Colors.black,
                              ),
                              dialogBackgroundColor:
                                  isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      DateFormat('yyyy년 MM월 dd일').format(selectedDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.amber.shade300
                            : Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '취소',
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'title': titleController.text.trim(),
                    'dueDate': selectedDate,
                  });
                } else {
                  // 내용이 비어있으면 경고 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('목표 내용을 입력해주세요'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? Colors.amber.shade700 : Colors.amber.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('추가'),
            ),
          ],
        );
      }),
    );

    if (result != null) {
      // 새 할 일 추가
      final newTodo = TodoItem(
        title: result['title'],
        dueDate: result['dueDate'],
      );

      try {
        // 데이터베이스에 추가
        final addedTodo = await _todoService.addTodo(newTodo);

        // UI 업데이트
        setState(() {
          _todoItems.add(addedTodo);
        });

        // 캘린더 이벤트 업데이트
        await _loadEventCounts();

        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('새 목표가 추가되었습니다'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('할 일 추가 중 오류: $e');
        // 오류 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('목표 추가 중 오류가 발생했습니다'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTodoCompleted(TodoItem todo) async {
    if (todo.id == null) return;

    final newStatus = !todo.isCompleted;

    try {
      // 데이터베이스 업데이트
      await _todoService.toggleCompleted(todo.id!, newStatus);

      // UI 업데이트 - 항목 상태만 변경하고 목록에서 제거하지 않음
      setState(() {
        final index = _todoItems.indexWhere((item) => item.id == todo.id);
        if (index != -1) {
          _todoItems[index] = todo.copyWith(isCompleted: newStatus);
        }

        // 섹션을 사용하는 경우 아래와 같이 업데이트
        _activeTodos = _todoItems.where((item) => !item.isCompleted).toList();
        _completedTodos = _todoItems.where((item) => item.isCompleted).toList();
      });

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? '목표를 완료했습니다! 🎉' : '목표를 다시 진행 중으로 표시했습니다'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newStatus ? Colors.green : Colors.blue,
        ),
      );
    } catch (e) {
      print('할 일 상태 변경 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('상태 변경 중 오류가 발생했습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 할 일 삭제
  Future<void> _deleteTodo(TodoItem todo) async {
    if (todo.id == null) return;

    try {
      // 데이터베이스에서 삭제
      await _todoService.deleteTodo(todo.id!);

      // UI 업데이트
      setState(() {
        _todoItems.removeWhere((item) => item.id == todo.id);
      });

      // 캘린더 이벤트 업데이트
      await _loadEventCounts();

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('목표가 삭제되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('할 일 삭제 중 오류: $e');
      // 오류 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 중 오류가 발생했습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 이벤트 마커 빌더
  List<Widget> _buildEventMarkers(DateTime date) {
    final count = _eventCounts[DateTime(date.year, date.month, date.day)] ?? 0;
    if (count == 0) return [];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return [
      Container(
        margin: EdgeInsets.symmetric(horizontal: 1.5),
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();

    // 학습 진행 상황 계산
    final int totalWords = widget.dayCollections.values
        .fold(0, (sum, words) => sum + words.length);
    final int memorizedWords = widget.dayCollections.values.fold(
        0, (sum, words) => sum + words.where((w) => w.isMemorized).length);
    final double progressPercentage =
        totalWords > 0 ? memorizedWords / totalWords : 0.0;

    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
              ),
            ),
          )
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 인사말 및 날짜
                  Row(
                    children: [
                      Text(
                        '🐹 안녕하세요!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(today),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '오늘도 영어 단어 학습을 시작해볼까요?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),

                  // 학습 진행 상황 카드
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '전체 학습 진행 상황',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progressPercentage,
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode
                                  ? Colors.amber[400]!
                                  : Colors.amber[700]!,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '암기한 단어: $memorizedWords개',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '전체 단어: $totalWords개',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: widget.onAddWord,
                                icon: Icon(Icons.add),
                                label: Text('단어 추가하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.amber[700]
                                      : Colors.amber[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // 캘린더
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '학습 캘린더',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.view_week),
                                    onPressed: () {
                                      setState(() {
                                        _calendarFormat = CalendarFormat.week;
                                      });
                                    },
                                    tooltip: '주간 보기',
                                    color:
                                        _calendarFormat == CalendarFormat.week
                                            ? Theme.of(context).primaryColor
                                            : null,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.calendar_month),
                                    onPressed: () {
                                      setState(() {
                                        _calendarFormat = CalendarFormat.month;
                                      });
                                    },
                                    tooltip: '월간 보기',
                                    color:
                                        _calendarFormat == CalendarFormat.month
                                            ? Theme.of(context).primaryColor
                                            : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              _loadTodosForSelectedDate();
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                              _loadEventCounts();
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.amber[700]!.withOpacity(0.5)
                                    : Colors.amber[200]!,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.amber[700]!
                                    : Colors.amber[600]!,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.green[700]!
                                    : Colors.green[600]!,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _buildEventMarkers(date),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

// 학습 목표 (TodoList)
// 학습 목표 (TodoList) 부분을 아래와 같이 수정합니다
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '학습 목표',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle),
                                onPressed: _showAddTodoDialog,
                                tooltip: '새 목표 추가',
                                color: isDarkMode
                                    ? Colors.green[300]
                                    : Colors.green[700],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (_activeTodos.isEmpty && _completedTodos.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  '아직 등록된 학습 목표가 없습니다',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 진행 중인 항목 섹션
                                if (_activeTodos.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, bottom: 12.0),
                                    child: Text(
                                      '진행 중인 목표',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.green.shade300
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: _activeTodos.length,
                                    itemBuilder: (context, index) {
                                      final item = _activeTodos[index];
                                      final isToday =
                                          isSameDay(item.dueDate, today);
                                      final bool isPast = item.dueDate.isBefore(
                                          DateTime(today.year, today.month,
                                              today.day));

                                      return Dismissible(
                                        key: Key(
                                            'todo_active_${item.id ?? index}_${item.title}'),
                                        background: Container(
                                          color: Colors.green,
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.only(left: 16),
                                          child: Icon(Icons.check,
                                              color: Colors.white),
                                        ),
                                        secondaryBackground: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(right: 16),
                                          child: Icon(Icons.delete,
                                              color: Colors.white),
                                        ),
                                        confirmDismiss: (direction) async {
                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            // 오른쪽으로 스와이프 - 삭제 확인
                                            return await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text('목표 삭제'),
                                                    content: Text(
                                                        '이 학습 목표를 삭제하시겠습니까?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: Text('취소'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: Text('삭제'),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ) ??
                                                false;
                                          } else {
                                            // 왼쪽으로 스와이프 - 완료 확인
                                            return await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text('목표 완료'),
                                                    content: Text(
                                                        '이 학습 목표를 완료로 표시하시겠습니까?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: Text('취소'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: Text('완료'),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ) ??
                                                false;
                                          }
                                        },
                                        onDismissed: (direction) {
                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            // 오른쪽으로 스와이프 - 삭제
                                            _deleteTodo(item);
                                          } else {
                                            // 왼쪽으로 스와이프 - 완료
                                            _toggleTodoCompleted(item);
                                          }
                                          // 중요: setState를 호출하여 UI를 즉시 업데이트
                                          setState(() {
                                            // 스와이프 후 UI에서 제거 (실제 데이터는 이미 업데이트되었음)
                                            _activeTodos.removeWhere(
                                                (todo) => todo.id == item.id);
                                          });
                                        },
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 16,
                                          ),
                                          title: Text(item.title),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 12,
                                                color: isPast
                                                    ? Colors.red
                                                    : isToday
                                                        ? (isDarkMode
                                                            ? Colors.amber[300]
                                                            : Colors.amber[700])
                                                        : Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                isToday
                                                    ? '오늘'
                                                    : DateFormat('yyyy-MM-dd')
                                                        .format(item.dueDate),
                                                style: TextStyle(
                                                  color: isPast
                                                      ? Colors.red
                                                      : isToday
                                                          ? (isDarkMode
                                                              ? Colors
                                                                  .amber[300]
                                                              : Colors
                                                                  .amber[700])
                                                          : Colors.grey,
                                                  fontWeight: isToday
                                                      ? FontWeight.bold
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Checkbox(
                                            value: false, // 진행 중인 항목은 항상 false
                                            onChanged: (value) {
                                              if (value != null && value) {
                                                _toggleTodoCompleted(item);
                                              }
                                            },
                                            activeColor: isDarkMode
                                                ? Colors.green[700]
                                                : Colors.green[600],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                // 완료된 항목 섹션
                                if (_completedTodos.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 24.0, bottom: 12.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          '완료된 목표',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${_completedTodos.length}개',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: _completedTodos.length,
                                    itemBuilder: (context, index) {
                                      final item = _completedTodos[index];

                                      return Dismissible(
                                        key: Key(
                                            'todo_completed_${item.id ?? index}_${item.title}'),
                                        background: Container(
                                          color: Colors.blue,
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.only(left: 16),
                                          child: Icon(Icons.replay,
                                              color: Colors.white),
                                        ),
                                        secondaryBackground: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(right: 16),
                                          child: Icon(Icons.delete,
                                              color: Colors.white),
                                        ),
                                        confirmDismiss: (direction) async {
                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            // 오른쪽으로 스와이프 - 삭제 확인
                                            return await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text('목표 삭제'),
                                                    content: Text(
                                                        '이 완료된 목표를 삭제하시겠습니까?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: Text('취소'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: Text('삭제'),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ) ??
                                                false;
                                          } else {
                                            // 왼쪽으로 스와이프 - 진행 중으로 변경 확인
                                            return await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text('목표 상태 변경'),
                                                    content: Text(
                                                        '이 목표를 다시 진행 중으로 변경하시겠습니까?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: Text('취소'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: Text('변경'),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ) ??
                                                false;
                                          }
                                        },
                                        onDismissed: (direction) {
                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            // 오른쪽으로 스와이프 - 삭제
                                            _deleteTodo(item);
                                          } else {
                                            // 왼쪽으로 스와이프 - 진행 중으로 변경
                                            _toggleTodoCompleted(item);
                                          }
                                          // 중요: setState를 호출하여 UI를 즉시 업데이트
                                          setState(() {
                                            // 스와이프 후 UI에서 제거 (실제 데이터는 이미 업데이트되었음)
                                            _completedTodos.removeWhere(
                                                (todo) => todo.id == item.id);
                                          });
                                        },
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 16,
                                          ),
                                          title: Text(
                                            item.title,
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 12,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                DateFormat('yyyy-MM-dd')
                                                    .format(item.dueDate),
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Checkbox(
                                            value: true, // 완료된 항목은 항상 true
                                            onChanged: (value) {
                                              if (value != null && !value) {
                                                _toggleTodoCompleted(item);
                                              }
                                            },
                                            activeColor: isDarkMode
                                                ? Colors.green[700]
                                                : Colors.green[600],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          );
  }
}
