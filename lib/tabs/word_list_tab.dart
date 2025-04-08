// lib/screens/tabs/word_list_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/screens/word_edit_screen.dart';
import 'package:vocabulary_app/services/storage_service.dart';
import 'package:vocabulary_app/services/tts_service.dart';
import 'package:vocabulary_app/widgets/word_card_widget.dart';

class WordListTab extends StatefulWidget {
  final Map<String, List<WordEntry>> dayCollections;
  final String currentDay;
  final Function(String) onDayChanged;
  final Function() navigateToCaptureTab;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final StorageService storageService;

  const WordListTab({
    Key? key,
    required this.dayCollections,
    required this.currentDay,
    required this.onDayChanged,
    required this.navigateToCaptureTab,
    required this.onSpeakWord,
    required this.storageService,
  }) : super(key: key);

  @override
  State<WordListTab> createState() => _WordListTabState();
}

class _WordListTabState extends State<WordListTab> {
  late String _currentDay;
  late Map<String, List<WordEntry>> _dayCollections;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.currentDay;
    _dayCollections = widget.dayCollections;
  }

  @override
  void didUpdateWidget(WordListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDay != widget.currentDay ||
        oldWidget.dayCollections != widget.dayCollections) {
      _currentDay = widget.currentDay;
      _dayCollections = widget.dayCollections;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dayCollections.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildDaySelector(),
        // 단어 통계 정보 표시
        if (_dayCollections[_currentDay]?.isNotEmpty ?? false)
          _buildStatistics(),
        // 선택된 DAY의 단어 목록
        Expanded(
          child: _buildWordList(),
        ),
      ],
    );
  }

  // 빈 상태 UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 24),
          Text(
            '단어장이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '이미지를 촬영하여 단어를 추가하세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.navigateToCaptureTab,
            icon: Icon(Icons.add_photo_alternate),
            label: Text('단어 추가하기'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade700 // 다크모드
                  : Colors.green.shade500, // 라이트모드
              foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
            ),
          ),
        ],
      ),
    );
  }

  // 단어장 선택기
  Widget _buildDaySelector() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            offset: Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '단어장 선택',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1.5,
                    ),
                    color: theme.cardColor,
                  ),
                  child: GestureDetector(
                    onTap: _showDaySelectionBottomSheet,
                    child: Container(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dayCollections.keys.contains(_currentDay)
                                  ? _currentDay
                                  : _dayCollections.keys.first,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.blue.shade900.withOpacity(0.3)
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_dayCollections[_currentDay]?.length ?? 0}단어',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: theme.iconTheme.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.red.shade900.withOpacity(0.3)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDeleteDayDialog(_currentDay),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.delete,
                        color: isDarkMode
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 단어장 선택 바텀시트
  void _showDaySelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 핸들바
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '단어장 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          Navigator.pop(context);
                          _showNewDayDialog();
                        },
                        tooltip: '새 단어장',
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade300
                            : Colors.blue,
                      ),
                    ],
                  ),
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _dayCollections.length,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final day = _dayCollections.keys.elementAt(index);
                      final isSelected = day == _currentDay;
                      final count = _dayCollections[day]?.length ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                // 바텀시트 내부 상태 변경
                              });

                              // 현재 단어장 변경
                              _updateCurrentDay(day);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue.shade900.withOpacity(0.3)
                                        : Colors.blue.shade50)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.blue.shade700
                                          : Colors.blue.shade300)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 체크 아이콘 (선택된 항목)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.blue.shade800
                                              : Colors.blue)
                                          : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade200),
                                      shape: BoxShape.circle,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          day,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? (Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.blue.shade300
                                                    : Colors.blue.shade800)
                                                : Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color,
                                          ),
                                        ),
                                        if (count > 0)
                                          Text(
                                            '${count}개 단어',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        // 선택한 단어장으로 먼저 설정
                                        _updateCurrentDay(day);

                                        // 바텀시트 닫기
                                        Navigator.pop(context);

                                        // 선택한 단어장의 단어들을 편집 화면으로 전달
                                        _navigateToEditDayWords(day);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '수정',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 새 단어장 생성 다이얼로그
  void _showNewDayDialog() {
    // 다음 DAY 번호 계산 - 안전하게 수정
    int nextDayNum = 1;

    if (_dayCollections.isNotEmpty) {
      try {
        // 유효한 DAY 형식의 키만 필터링
        List<int> validDayNumbers = [];

        for (var day in _dayCollections.keys) {
          // 정규식으로 "DAY " 다음에 오는 숫자 추출
          final match = RegExp(r'DAY\s+(\d+)').firstMatch(day);
          if (match != null && match.group(1) != null) {
            validDayNumbers.add(int.parse(match.group(1)!));
          }
        }

        if (validDayNumbers.isNotEmpty) {
          // 가장 큰 DAY 번호 찾기
          nextDayNum = validDayNumbers.reduce((a, b) => a > b ? a : b) + 1;
        }
      } catch (e) {
        print('DAY 번호 계산 중 오류 발생: $e');
        // 오류 발생 시 기본값 1 사용
        nextDayNum = 1;
      }
    }

    final String suggestedDay = 'DAY $nextDayNum';
    final TextEditingController controller =
        TextEditingController(text: suggestedDay);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(
              Icons.create_new_folder,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade300
                  : Colors.green,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              '새 단어장 만들기',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '새 단어장 이름을 입력하세요',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: '예: DAY 1',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.folder_open),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('취소'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newDayName = controller.text.trim();
              if (newDayName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('단어장 이름을 입력해주세요'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              // 이미 존재하는 이름인지 확인
              if (_dayCollections.containsKey(newDayName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('이미 존재하는 단어장 이름입니다'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              // 새 단어장 생성
              _createNewDayCollection(newDayName);
              Navigator.of(context).pop();
            },
            child: Text('생성'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade700
                  : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // 단어장 삭제 다이얼로그
  Future<void> _showDeleteDayDialog(String dayName) async {
    // "기타" 단어장은 day가 null인 단어들의 모음
    final bool isNullDayCollection = dayName == '기타';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            SizedBox(width: 8),
            Text('단어장 삭제'),
          ],
        ),
        content: Text(
            '$dayName 단어장을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며, 해당 단어장의 모든 단어가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteDayCollection(dayName, isNullDayCollection);
    }
  }

  // 통계 정보 표시
  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStatCard(
            '총 단어',
            '${_dayCollections[_currentDay]?.length ?? 0}',
            Colors.blue,
            Icons.format_list_numbered,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            '암기 완료',
            '${_dayCollections[_currentDay]?.where((w) => w.isMemorized).length ?? 0}',
            Colors.green,
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(
      String title, String value, MaterialColor color, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크모드에 맞는 색상 생성
    final backgroundColor = isDarkMode
        ? Color.fromRGBO(
            color.shade900.red, color.shade900.green, color.shade900.blue, 0.3)
        : color.shade50;

    final iconBackgroundColor = isDarkMode
        ? Color.fromRGBO(
            color.shade800.red, color.shade800.green, color.shade800.blue, 0.5)
        : color.shade100;

    final iconColor = isDarkMode ? color.shade300 : color.shade700;
    final titleColor = isDarkMode ? color.shade300 : color.shade700;
    final valueColor = isDarkMode ? color.shade100 : color.shade900;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: titleColor),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 단어 목록
  Widget _buildWordList() {
    if (_dayCollections[_currentDay]?.isEmpty ?? true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add,
              size: 60,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              '$_currentDay에 저장된 단어가 없습니다.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.navigateToCaptureTab,
              child: Text('단어 추가하기'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green.shade700 // 다크모드
                    : Colors.green.shade500, // 라이트모드
                foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 24),
        itemCount: _dayCollections[_currentDay]?.length ?? 0,
        physics: BouncingScrollPhysics(), // 스크롤 애니메이션 개선
        itemBuilder: (context, index) {
          final word = _dayCollections[_currentDay]![index];

          // 애니메이션이 적용된 단어 카드 사용
          return AnimatedWordCard(
            word: word,
            onSpeakWord: widget.onSpeakWord,
            onUpdateMemorizedStatus: (String wordText, bool isMemorized) async {
              await _updateMemorizedStatus(word, isMemorized);
            },
            index: index,
          );
        },
      ),
    );
  }

  // 단어장 수정 화면으로 이동
  Future<void> _navigateToEditDayWords(String dayName) async {
    // 선택한 단어장의 모든 단어 불러오기
    List<WordEntry> dayWords = _dayCollections[dayName] ?? [];

    if (dayWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dayName에 저장된 단어가 없습니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // 단어 편집 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordEditScreen(
          words: dayWords,
          dayName: dayName,
        ),
      ),
    );

    // 편집 화면에서 돌아왔을 때 처리
    if (result != null && result is Map) {
      try {
        final List<WordEntry> editedWords = result['words'];
        final String editedDayName = result['dayName'];

        // 단어장 이름이 변경되었다면 처리
        if (editedDayName != dayName) {
          print('단어장 이름 변경: $dayName -> $editedDayName');

          // 기존 단어장 삭제
          await widget.storageService.deleteDay(dayName);

// 새 단어장에 모두 저장
          for (var i = 0; i < editedWords.length; i++) {
            editedWords[i] = editedWords[i].copyWith(day: editedDayName);
          }

          // 새 단어장 저장
          await widget.storageService.saveWords(editedWords);
          await widget.storageService
              .saveDayCollection(editedDayName, editedWords.length);

          // 상태 업데이트
          setState(() {
            // 기존 단어장 제거
            _dayCollections.remove(dayName);

            // 새 단어장 추가
            _dayCollections[editedDayName] = editedWords;
            _currentDay = editedDayName;
          });

          // 부모 위젯에 변경 알림
          widget.onDayChanged(editedDayName);
        } else {
          // 단어장 이름은 동일하고 내용만 변경된 경우
          // 단어 저장
          await widget.storageService.saveWords(editedWords);

          // 단어장 정보 업데이트
          await widget.storageService
              .saveDayCollection(dayName, editedWords.length);

          // 상태 업데이트
          setState(() {
            _dayCollections[dayName] = editedWords;
          });
        }

        // 완료 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어장이 업데이트되었습니다.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        print('단어장 업데이트 중 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어장 업데이트 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // 현재 단어장 업데이트
  void _updateCurrentDay(String day) {
    setState(() {
      _currentDay = day;
    });
    widget.onDayChanged(day);
  }

  // 새 단어장 생성
  Future<void> _createNewDayCollection(String newDayName) async {
    try {
      // 새 단어장 생성
      setState(() {
        _dayCollections[newDayName] = [];
        _currentDay = newDayName;
      });

      // 단어장 정보 저장
      await widget.storageService.saveDayCollection(newDayName, 0);

      // 부모 위젯에 변경 알림
      widget.onDayChanged(newDayName);

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('새 단어장이 생성되었습니다: $newDayName'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('단어장 생성 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어장 생성 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // 단어장 삭제
  Future<void> _deleteDayCollection(
      String dayName, bool isNullDayCollection) async {
    try {
      // 단어장 삭제 전 해당 단어장의 단어 수 확인
      final wordsCount = _dayCollections[dayName]?.length ?? 0;
      print('단어장 "$dayName" 삭제 시작 (UI): $wordsCount개 단어 포함');

      if (isNullDayCollection) {
        // "기타" 단어장 처리 (day가 null인 단어들 삭제)
        print('"기타" 단어장 삭제 - day가 null인 단어들 삭제');

        // day가 null인 단어들 모두 삭제
        await widget.storageService.deleteNullDayWords();

        print('day가 null인 단어 삭제 완료');
      } else {
        // 일반 단어장 삭제 처리
        await widget.storageService.deleteDay(dayName);
      }

      // 상태 업데이트
      setState(() {
        _dayCollections.remove(dayName);

        // 다른 단어장으로 이동
        if (_dayCollections.isEmpty) {
          _currentDay = 'DAY 1'; // 기본값 설정
        } else {
          _currentDay = _dayCollections.keys.first;
        }
      });

      // 부모 위젯에 변경 알림
      widget.onDayChanged(_currentDay);

      // 저장소 상태 확인
      await widget.storageService.validateStorage();

      // 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dayName 단어장이 삭제되었습니다. ($wordsCount개 단어 함께 삭제)'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('단어장 삭제 중 오류 (UI): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어장 삭제 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // 암기 상태 업데이트
  Future<void> _updateMemorizedStatus(WordEntry word, bool isMemorized) async {
    try {
      // 스토리지에 상태 업데이트
      await widget.storageService.updateMemorizedStatus(word.word, isMemorized);

      // UI 상태 업데이트
      setState(() {
        final index = _dayCollections[_currentDay]!.indexOf(word);
        if (index >= 0) {
          _dayCollections[_currentDay]![index] =
              word.copyWith(isMemorized: isMemorized);
        }
      });
    } catch (e) {
      print('암기 상태 업데이트 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('암기 상태 업데이트 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
