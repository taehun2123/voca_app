import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';
import 'package:vocabulary_app/widgets/smart_study_card.dart';

class SmartStudyScreen extends StatefulWidget {
  final List<WordEntry> words;
  final String dayName;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(WordEntry) onWordMemorized;
  final Function(WordEntry, bool) onQuizAnswered;

  const SmartStudyScreen({
    Key? key,
    required this.words,
    required this.dayName,
    required this.onSpeakWord,
    required this.onWordMemorized,
    required this.onQuizAnswered,
  }) : super(key: key);

  @override
  _SmartStudyScreenState createState() => _SmartStudyScreenState();
}

class _SmartStudyScreenState extends State<SmartStudyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 학습 모드별 단어 목록
  List<WordEntry> _difficultWords = [];
  List<WordEntry> _newWords = [];
  List<WordEntry> _reviewDueWords = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _prepareStudyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 부모 위젯이 콜백을 받아서 호출하는 부분
  void _onQuizAnswered(WordEntry word, bool isCorrect) {
    // 퀴즈 결과를 부모 위젯으로 전달
    widget.onQuizAnswered(word, isCorrect);

    // 콘솔에 로그 추가
    print('스마트 학습 화면: 퀴즈 결과 전달: ${word.word}, 정답: $isCorrect');
  }

  // 학습 데이터 준비
  void _prepareStudyData() {
    setState(() {
      _isLoading = true;
    });

    // 1. 어려운 단어 (난이도 높거나 정답률 낮은 단어)
    _difficultWords = widget.words.where((word) {
      // 난이도가 높거나 정답률이 낮은 단어 선택
      bool isHighDifficulty = word.difficulty >= 0.7;
      bool isLowCorrectRate = word.quizAttempts >= 2 &&
          (word.quizCorrect / word.quizAttempts) < 0.5;
      return isHighDifficulty || isLowCorrectRate;
    }).toList();

    // 2. 새 단어 (복습 횟수 적거나 퀴즈 시도 적은 단어)
    _newWords = widget.words.where((word) {
      return word.reviewCount < 3 || word.quizAttempts < 2;
    }).toList();

    // 3. 복습 필요한 단어 (일정 시간 지난 단어들)
    _reviewDueWords = widget.words.where((word) {
      // 이미 암기된 단어들 중에서 일정 기간 지난 단어들
      // 스페이싱 효과(Spacing Effect)를 활용한 복습 대상 선정
      if (!word.isMemorized) return false;

      final now = DateTime.now();
      final daysSinceCreated = now.difference(word.createdAt).inDays;

      // 복습 간격 계산 (간단한 예시: 복습 횟수에 따라 간격 증가)
      // 복습 횟수 0-1: 1일, 2-3: 3일, 4-5: 7일, 6+: 14일
      int reviewInterval;
      if (word.reviewCount < 2) {
        reviewInterval = 1;
      } else if (word.reviewCount < 4) {
        reviewInterval = 3;
      } else if (word.reviewCount < 6) {
        reviewInterval = 7;
      } else {
        reviewInterval = 14;
      }

      // 마지막 복습일로부터 복습 간격 이상 지났는지 확인
      return daysSinceCreated >= reviewInterval;
    }).toList();

    // 목록 정렬 및 중복 제거
    _difficultWords.sort((a, b) => b.difficulty.compareTo(a.difficulty));
    _newWords.sort((a, b) => a.reviewCount.compareTo(b.reviewCount));

    // 중복 제거: 어려운 단어가 새 단어에도 포함된 경우 새 단어에서 제거
    _newWords = _newWords
        .where((word) =>
            !_difficultWords.any((difficult) => difficult.word == word.word))
        .toList();

    // 복습 단어에서도 중복 제거
    _reviewDueWords = _reviewDueWords
        .where((word) =>
            !_difficultWords.any((difficult) => difficult.word == word.word) &&
            !_newWords.any((newWord) => newWord.word == word.word))
        .toList();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('스마트 학습: ${widget.dayName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded),
                  SizedBox(height: 4),
                  Text('어려운 단어'),
                  Text(
                    '(${_difficultWords.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.new_releases),
                  SizedBox(height: 4),
                  Text('새 단어'),
                  Text(
                    '(${_newWords.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay),
                  SizedBox(height: 4),
                  Text('복습 단어'),
                  Text(
                    '(${_reviewDueWords.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          labelColor:
              isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
          unselectedLabelColor:
              isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          indicatorColor:
              isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 어려운 단어 탭
                _buildWordList(_difficultWords, Colors.red),

                // 새 단어 탭
                _buildWordList(_newWords, Colors.blue),

                // 복습 단어 탭
                _buildWordList(_reviewDueWords, Colors.green),
              ],
            ),
    );
  }

  Widget _buildWordList(List<WordEntry> words, MaterialColor color) {
    if (words.isEmpty) {
      return _buildEmptyState(color);
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: words.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 300),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: SmartStudyCard(
                  word: words[index],
                  onSpeakWord: widget.onSpeakWord,
                  onMemorized: () => widget.onWordMemorized(words[index]),
                  onQuizAnswered: (bool isCorrect) =>
                      widget.onQuizAnswered(words[index], isCorrect),
                  color: color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(MaterialColor color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String message;
    IconData icon;

    if (color == Colors.red) {
      message = '어려운 단어가 없습니다!';
      icon = Icons.emoji_events;
    } else if (color == Colors.blue) {
      message = '새로운 단어가 없습니다!';
      icon = Icons.thumb_up;
    } else {
      message = '복습할 단어가 없습니다!';
      icon = Icons.check_circle;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: isDarkMode ? color.shade300 : color.shade200,
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _prepareStudyData,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? color.shade700 : color.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('새로고침'),
          ),
        ],
      ),
    );
  }
}
