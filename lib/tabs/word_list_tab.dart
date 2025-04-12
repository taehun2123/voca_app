// lib/screens/tabs/word_list_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/screens/word_edit_screen.dart';
import 'package:vocabulary_app/services/storage_service.dart';
import 'package:vocabulary_app/services/tts_service.dart';
import 'package:vocabulary_app/widgets/dialogs/day_selection_bottom_sheet.dart';
import 'package:vocabulary_app/widgets/dialogs/delete_day_dialog.dart';
import 'package:vocabulary_app/widgets/dialogs/new_day_dialog.dart';
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
                  ? Colors.amber.shade700 // 다크모드
                  : Colors.amber.shade500, // 라이트모드
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
  showDaySelectionBottomSheet(
    context: context,
    dayCollections: _dayCollections,
    currentDay: _currentDay,
    onDaySelected: _updateCurrentDay,
    onEditDayWords: _navigateToEditDayWords,
    onCreateNewDay: _showNewDayDialog,
  );
}

// 새 단어장 다이얼로그 표시
void _showNewDayDialog() async {
  // 다음 DAY 번호 계산
  int nextDayNum = _calculateNextDayNumber();

  // 분리된 다이얼로그 사용
  final newDayName = await showNewDayDialog(
    context: context,
    nextDayNum: nextDayNum,
  );

  // 결과 처리
  if (newDayName != null && newDayName.isNotEmpty) {
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
  }
}

// WordListTab 클래스 내부에 추가할 메서드
int _calculateNextDayNumber() {
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

  return nextDayNum;
}

// 단어장 삭제 다이얼로그 표시
Future<void> _showDeleteDayDialog(String dayName) async {
  // "기타" 단어장은 day가 null인 단어들의 모음
  final bool isNullDayCollection = dayName == '기타';

  // 분리된 다이얼로그 사용
  final confirmed = await showDeleteDayDialog(
    context: context,
    dayName: dayName,
  );

  if (confirmed) {
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
            Colors.lightBlue,
            Icons.format_list_numbered,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            '암기 완료',
            '${_dayCollections[_currentDay]?.where((w) => w.isMemorized).length ?? 0}',
            Colors.amber,
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
                    ? Colors.amber.shade700 // 다크모드
                    : Colors.amber.shade500, // 라이트모드
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
