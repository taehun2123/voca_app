// lib/screens/direct_input_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';
import 'package:vocabulary_app/widgets/quiz_result_card.dart';

class DirectInputQuizScreen extends StatefulWidget {
  final List<WordEntry> words;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(WordEntry, bool) onQuizAnswered; // 정답률 업데이트를 위한 콜백

  const DirectInputQuizScreen({
    Key? key,
    required this.words,
    required this.onSpeakWord,
    required this.onQuizAnswered,
  }) : super(key: key);

  @override
  _DirectInputQuizScreenState createState() => _DirectInputQuizScreenState();
}

class _DirectInputQuizScreenState extends State<DirectInputQuizScreen> {
  int _currentIndex = 0;
  List<WordEntry> _quizWords = [];
  TextEditingController _answerController = TextEditingController();
  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  bool _isPartiallyCorrect = false;
  String _correctAnswer = '';
  AccentType _selectedAccent = AccentType.american;

  // 퀴즈 결과 저장
  List<WordEntry> _wrongAnswers = [];
  List<WordEntry> _partiallyCorrectAnswers = [];

  // 힌트 관련
  bool _showHint = false;
  String _hintText = '';
  int _hintLevel = 0;

  bool _showingResults = false;

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DirectInputQuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.words != widget.words) {
      _prepareQuiz();
    }
  }

  void _prepareQuiz() {
    if (widget.words.length < 4) {
      _quizWords = [];
      return;
    }

    // 퀴즈용 단어 선택 (모든 단어 사용하되 섞기)
    _quizWords = List.from(widget.words);
    _quizWords.shuffle();
    _currentIndex = 0;
    _resetAnswer();

    // 결과 리스트 초기화
    _wrongAnswers = [];
    _partiallyCorrectAnswers = [];

    setState(() {
      _showingResults = false;
    });
  }

  void _resetAnswer() {
    _answerController.clear();
    _isAnswerChecked = false;
    _isAnswerCorrect = false;
    _isPartiallyCorrect = false;
    _showHint = false;
    _hintText = '';
    _hintLevel = 0;
  }

// 기존 _extractKeywords 메서드 개선
  List<String> _extractKeywords(String text) {
    // 특수문자 및 구두점 제거
    String cleaned = text.replaceAll(RegExp(r'[^\w\s가-힣]'), '');

    // 의미없는 단어들 제거 (조사, 관사 등)
    List<String> stopWords = [
      '은',
      '는',
      '이',
      '가',
      '을',
      '를',
      '에',
      '의',
      '로',
      '으로',
      'a',
      'an',
      'the',
      'to',
      'in',
      'on',
      'of',
      'for'
    ];

    // 단어로 분리하고 필터링
    List<String> words = cleaned
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !stopWords.contains(word))
        .toList();

    return words;
  }

// 개선된 _checkAnswer 메서드
  void _checkAnswer() {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('답을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userAnswer = _answerController.text.trim().toLowerCase();
    final currentWord = _quizWords[_currentIndex];
    _correctAnswer = currentWord.meaning;

    // 정답 체크 - 의미는 여러 가지 표현이 있을 수 있으므로 포함 관계 확인
    final meaningKeywords = _extractKeywords(currentWord.meaning);
    final userAnswerKeywords = _extractKeywords(userAnswer);

    if (meaningKeywords.isEmpty || userAnswerKeywords.isEmpty) {
      // 키워드가 추출되지 않은 경우, 대안으로 단순 문자열 비교
      _isAnswerCorrect = userAnswer == currentWord.meaning.toLowerCase();
      _isPartiallyCorrect = !_isAnswerCorrect &&
          (userAnswer.contains(currentWord.meaning.toLowerCase()) ||
              currentWord.meaning.toLowerCase().contains(userAnswer));
    } else {
      // 키워드 매칭 방식 개선
      int matchCount = 0;
      for (var keyword in meaningKeywords) {
        // 핵심 단어가 정확히 포함되어 있는지 확인
        bool hasMatch = userAnswerKeywords.any((userKeyword) {
          // 1. 정확히 일치하는 경우
          if (userKeyword == keyword) return true;

          // 2. 짧은 키워드(3글자 이상)가 긴 키워드에 정확히 포함되는 경우
          if (keyword.length >= 3 && userKeyword.contains(keyword)) return true;
          if (userKeyword.length >= 3 && keyword.contains(userKeyword))
            return true;

          // 3. 레벤슈타인 거리 계산 (비슷한 문자열 체크)
          int distance = _calculateLevenshteinDistance(userKeyword, keyword);
          return distance <= 1 && keyword.length > 3; // 긴 단어만 오타 허용
        });

        if (hasMatch) matchCount++;
      }

      double matchRatio = meaningKeywords.isNotEmpty
          ? matchCount / meaningKeywords.length
          : 0.0;

      // 80% 이상 매칭되면 정답, 50% 이상 매칭되면 부분 정답
      _isAnswerCorrect = matchRatio >= 0.8;
      _isPartiallyCorrect = !_isAnswerCorrect && matchRatio >= 0.5;
    }

    setState(() {
      _isAnswerChecked = true;
    });

    // 퀴즈 결과 저장
    if (!_isAnswerCorrect) {
      if (_isPartiallyCorrect) {
        _partiallyCorrectAnswers.add(currentWord);
      } else {
        _wrongAnswers.add(currentWord);
      }
    }

    // 정답률 업데이트 콜백 호출
    widget.onQuizAnswered(currentWord, _isAnswerCorrect);
  }

// 레벤슈타인 거리 계산 - 두 문자열 간의 유사도 측정 (오타 허용)
  int _calculateLevenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<List<int>> dp = List.generate(
        a.length + 1, (i) => List.generate(b.length + 1, (j) => 0));

    for (int i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }

    for (int j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1, // 삭제
          dp[i][j - 1] + 1, // 삽입
          dp[i - 1][j - 1] + cost // 교체 또는 일치
        ].reduce((curr, next) => curr < next ? curr : next);
      }
    }

    return dp[a.length][b.length];
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _quizWords.length) {
        _resetAnswer();
      } else {
        // 퀴즈 완료 - 결과 표시
        _showResults();
      }
    });
  }

  void _showResults() {
    setState(() {
      _showingResults = true;
    });
  }

  void _restartQuiz() {
    _prepareQuiz();
  }

  void _restartWithMistakes() {
    // 틀린 단어와 부분 정답 단어로 새 퀴즈 생성
    setState(() {
      _quizWords = [..._wrongAnswers, ..._partiallyCorrectAnswers];
      _quizWords.shuffle();
      _currentIndex = 0;
      _resetAnswer();
      _wrongAnswers = [];
      _partiallyCorrectAnswers = [];
      _showingResults = false;
    });
  }

  void _showAnswerHint() {
    final currentWord = _quizWords[_currentIndex];
    final meaning = currentWord.meaning;

    setState(() {
      _showHint = true;
      _hintLevel++;

      // 힌트 레벨에 따라 다른 힌트 제공
      if (_hintLevel == 1) {
        // 첫 힌트: 첫 글자 보여주기
        _hintText = meaning.substring(0, 1) + " " + "○" * (meaning.length - 1);
      } else if (_hintLevel == 2) {
        // 두 번째 힌트: 몇 개 글자 더 보여주기 (약 30%)
        int revealCount = (meaning.length * 0.3).round();
        revealCount = revealCount < 1 ? 1 : revealCount;

        List<String> chars = meaning.split('');
        List<String> hintChars = List.filled(meaning.length, '○');

        // 첫 글자는 항상 공개
        hintChars[0] = chars[0];

        // 나머지 공개 글자 랜덤 선택
        List<int> indices = List.generate(meaning.length - 1, (i) => i + 1);
        indices.shuffle();

        for (int i = 0; i < revealCount - 1 && i < indices.length; i++) {
          hintChars[indices[i]] = chars[indices[i]];
        }

        _hintText = hintChars.join(' ');
      } else {
        // 세 번째 힌트: 글자 수 힌트와 설명
        _hintText = "정답은 ${meaning.length}글자이며, 완전한 뜻입니다. 정답을 확인하세요.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 퀴즈 데이터가 준비되지 않은 경우
    if (_quizWords.isEmpty) {
      return Center(
        child: Text(
          '퀴즈를 위해 최소 4개의 단어가 필요합니다.',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
      );
    }

    // 퀴즈 결과 화면
    if (_showingResults) {
      return _buildResultsScreen();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 진행 상태 표시
            _buildProgressIndicator(),
            SizedBox(height: 16),

            // 문제 카드
            _buildQuestionCard(),
            SizedBox(height: 24),

            // 답변 입력 필드
            _buildAnswerField(),
            SizedBox(height: 16),

            // 힌트 섹션
            if (_showHint && !_isAnswerChecked) _buildHintSection(),

            // 정답 확인 결과
            if (_isAnswerChecked) _buildAnswerResult(),

            SizedBox(height: 24),

            // 버튼 영역
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_currentIndex + 1} / ${_quizWords.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red.shade400,
                ),
                SizedBox(width: 4),
                Text(
                  '틀린 단어: ${_wrongAnswers.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade400,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: Colors.orange.shade400,
                ),
                SizedBox(width: 4),
                Text(
                  '부분 정답: ${_partiallyCorrectAnswers.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _quizWords.length,
          backgroundColor:
              isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Colors.amber.shade700 : Colors.amber.shade500,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentWord = _quizWords[_currentIndex];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode
              ? Colors.amber.shade700.withOpacity(0.6)
              : Colors.amber.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '다음 단어의 뜻을 입력하세요',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentWord.word,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                  ),
                  onPressed: () => widget.onSpeakWord(currentWord.word,
                      accent: _selectedAccent),
                  tooltip: '발음 듣기',
                ),
              ],
            ),
            if (currentWord.pronunciation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  currentWord.pronunciation,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정답 입력',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            hintText: '정답을 입력하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            enabled: !_isAnswerChecked,
            suffixIcon: !_isAnswerChecked
                ? IconButton(
                    icon: Icon(Icons.lightbulb_outline),
                    tooltip: '힌트 보기',
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                    onPressed: _showAnswerHint,
                  )
                : null,
          ),
          onSubmitted: (_) {
            if (!_isAnswerChecked) {
              _checkAnswer();
            }
          },
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHintSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.amber.shade900.withOpacity(0.3)
            : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.amber.shade800.withOpacity(0.6)
              : Colors.amber.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color:
                    isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '힌트',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.amber.shade300
                      : Colors.amber.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _hintText,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 1.5,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerResult() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData iconData;
    String resultText;

    if (_isAnswerCorrect) {
      bgColor = isDarkMode
          ? Colors.green.shade900.withOpacity(0.3)
          : Colors.green.shade50;
      borderColor = isDarkMode ? Colors.green.shade700 : Colors.green.shade300;
      textColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
      iconData = Icons.check_circle;
      resultText = '정답입니다!';
    } else if (_isPartiallyCorrect) {
      bgColor = isDarkMode
          ? Colors.orange.shade900.withOpacity(0.3)
          : Colors.orange.shade50;
      borderColor =
          isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300;
      textColor = isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
      iconData = Icons.remove_circle;
      resultText = '부분 정답입니다. 완전한 정답은:';
    } else {
      bgColor = isDarkMode
          ? Colors.red.shade900.withOpacity(0.3)
          : Colors.red.shade50;
      borderColor = isDarkMode ? Colors.red.shade700 : Colors.red.shade300;
      textColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
      iconData = Icons.cancel;
      resultText = '오답입니다. 정답은:';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconData,
                color: textColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                resultText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          if (!_isAnswerCorrect) ...[
            SizedBox(height: 8),
            Text(
              _correctAnswer,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '입력한 답: ${_answerController.text}',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isAnswerChecked)
          Expanded(
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? Colors.blue.shade700 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('정답 확인'),
            ),
          )
        else
          Expanded(
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? Colors.amber.shade700 : Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('다음 문제'),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 결과 헤더
          Text(
            '퀴즈 결과',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),

          // 점수 정보
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.amber.shade900.withOpacity(0.3)
                  : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.amber.shade800.withOpacity(0.6)
                    : Colors.amber.shade200,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '맞힌 문제 수',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${_quizWords.length - _wrongAnswers.length - _partiallyCorrectAnswers.length} / ${_quizWords.length}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '정답률: ${((_quizWords.length - _wrongAnswers.length - _partiallyCorrectAnswers.length) / _quizWords.length * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // 틀린 단어 및 부분 정답 단어 목록
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, size: 16),
                            SizedBox(width: 4),
                            Text('틀린 단어 (${_wrongAnswers.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_circle, size: 16),
                            SizedBox(width: 4),
                            Text('부분 정답 (${_partiallyCorrectAnswers.length})'),
                          ],
                        ),
                      ),
                    ],
                    labelColor: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                    unselectedLabelColor: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    indicatorColor: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 틀린 단어 탭
                        _wrongAnswers.isEmpty
                            ? _buildEmptyTabContent('틀린 단어가 없습니다!')
                            : _buildWrongWordsList(),

                        // 부분 정답 탭
                        _partiallyCorrectAnswers.isEmpty
                            ? _buildEmptyTabContent('부분 정답 단어가 없습니다!')
                            : _buildPartiallyCorrectWordsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restartQuiz,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                    side: BorderSide(
                      color: isDarkMode
                          ? Colors.amber.shade700
                          : Colors.amber.shade300,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('전체 다시 시작'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _wrongAnswers.isEmpty && _partiallyCorrectAnswers.isEmpty
                          ? null
                          : _restartWithMistakes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.amber.shade700
                        : Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                  child: Text('틀린 문제만 다시'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabContent(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: isDarkMode ? Colors.green.shade300 : Colors.green.shade600,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongWordsList() {
    return ListView.builder(
      itemCount: _wrongAnswers.length,
      itemBuilder: (context, index) {
        return QuizResultCard(
          word: _wrongAnswers[index],
          isCorrect: false,
          isPartiallyCorrect: false,
          onSpeakWord: widget.onSpeakWord,
        );
      },
    );
  }

  Widget _buildPartiallyCorrectWordsList() {
    return ListView.builder(
      itemCount: _partiallyCorrectAnswers.length,
      itemBuilder: (context, index) {
        return QuizResultCard(
          word: _partiallyCorrectAnswers[index],
          isCorrect: false,
          isPartiallyCorrect: true,
          onSpeakWord: widget.onSpeakWord,
        );
      },
    );
  }
}
