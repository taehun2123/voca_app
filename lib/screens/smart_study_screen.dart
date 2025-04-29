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

  void _onQuizAnswered(WordEntry word, bool isCorrect) {
    widget.onQuizAnswered(word, isCorrect);
    print('스마트 학습 화면: 퀴즈 결과 전달: ${word.word}, 정답: $isCorrect');
  }

  void _prepareStudyData() {
    setState(() {
      _isLoading = true;
    });

    _difficultWords = widget.words.where((word) {
      bool isHighDifficulty = word.difficulty >= 0.7;
      bool isLowCorrectRate = word.quizAttempts >= 2 &&
          (word.quizCorrect / word.quizAttempts) < 0.5;
      return isHighDifficulty || isLowCorrectRate;
    }).toList();

    _newWords = widget.words.where((word) {
      return word.reviewCount < 3 || word.quizAttempts < 2;
    }).toList();

    _reviewDueWords = widget.words.where((word) {
      if (!word.isMemorized) return false;
      final now = DateTime.now();
      final daysSinceCreated = now.difference(word.createdAt).inDays;
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
      return daysSinceCreated >= reviewInterval;
    }).toList();

    _difficultWords.sort((a, b) => b.difficulty.compareTo(a.difficulty));
    _newWords.sort((a, b) => a.reviewCount.compareTo(b.reviewCount));
    _newWords = _newWords
        .where((word) =>
            !_difficultWords.any((difficult) => difficult.word == word.word))
        .toList();
    _reviewDueWords = _reviewDueWords
        .where((word) =>
            !_difficultWords.any((difficult) => difficult.word == word.word) &&
            !_newWords.any((newWord) => newWord.word == word.word))
        .toList();

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildEmptyState(MaterialColor color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String message;
    String submessage = "";
    IconData icon;

    if (color == Colors.red) {
      message = '어려운 단어가 없습니다!';
      submessage = '어려운 단어는 퀴즈에서 정답률이 50% 미만이거나 난이도가 높은 단어입니다.';
      icon = Icons.emoji_events;
    } else if (color == Colors.blue) {
      message = '새로운 단어가 없습니다!';
      submessage = '새 단어는 복습 횟수가 3회 미만이거나 퀴즈 시도가 2회 미만인 단어입니다.';
      icon = Icons.thumb_up;
    } else {
      message = '복습할 단어가 없습니다!';
      submessage = '복습 단어는 암기 완료 표시된 단어 중 일정 기간이 지난 단어들입니다.\n'
          '(복습 횟수 0-1: 1일 후, 2-3: 3일 후, 4-5: 7일 후, 6+: 14일 후)';
      icon = Icons.check_circle;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDarkMode ? color.shade300 : color.shade400,
            ),
            SizedBox(height: 28),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.shade900.withOpacity(0.85)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? color.shade700.withOpacity(0.4)
                      : color.shade200.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Text(
                submessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 36),
            ElevatedButton(
              onPressed: _prepareStudyData,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? color.shade600 : color.shade400,
                foregroundColor: Colors.black,
                padding:
                    EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                '새로고침',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('스마트 학습: ${widget.dayName}'),
        elevation: 0,
        backgroundColor:
            isDarkMode ? Colors.grey.shade900 : Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(62), // 높이 약간 줄임
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: isDarkMode
                  ? Colors.amber.shade300
                  : Colors.amber.shade700,
              labelColor: isDarkMode
                  ? Colors.amber.shade300
                  : Colors.amber.shade700,
              unselectedLabelColor: isDarkMode
                  ? Colors.grey.shade500
                  : Colors.grey.shade500,
              labelPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), // vertical 패딩 제거
              tabs: [
                _buildTab(
                  icon: Icons.warning_amber_rounded,
                  label: '어려운 단어',
                  count: _difficultWords.length,
                  isDarkMode: isDarkMode,
                ),
                _buildTab(
                  icon: Icons.new_releases,
                  label: '새 단어',
                  count: _newWords.length,
                  isDarkMode: isDarkMode,
                ),
                _buildTab(
                  icon: Icons.replay,
                  label: '복습 단어',
                  count: _reviewDueWords.length,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWordList(_difficultWords, Colors.red),
                _buildWordList(_newWords, Colors.blue),
                _buildWordList(_reviewDueWords, Colors.green),
              ],
            ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required int count,
    required bool isDarkMode,
  }) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20, // 26에서 22로 크기 줄임
            color: null, 
          ),
          SizedBox(height: 2), // 8에서 2로 간격 줄임
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 11, // 13.5에서 12로 크기 줄임
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2), // 3에서 1로 간격 줄임
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
}
