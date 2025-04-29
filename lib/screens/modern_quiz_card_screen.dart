import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';

class ModernQuizScreen extends StatefulWidget {
  final List<WordEntry> words;
  final List<WordEntry> allWords;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(WordEntry, bool) onQuizAnswered; // 콜백 추가

  const ModernQuizScreen({
    Key? key,
    required this.words,
    required this.allWords,
    required this.onSpeakWord,
    required this.onQuizAnswered, // 콜백 추가
  }) : super(key: key);

  @override
  _ModernQuizScreenState createState() => _ModernQuizScreenState();
}

class _ModernQuizScreenState extends State<ModernQuizScreen> {
  int _currentIndex = 0;
  List<WordEntry> _quizWords = [];
  List<String> _options = [];
  String? _selectedOption;
  bool _showResult = false;
  int _correctAnswers = 0;
  int _totalAnswered = 0;

  bool _isReady = false;

  // 틀린 문제와 맞은 문제 추적
  List<WordEntry> _wrongAnswers = [];
  List<WordEntry> _correctWordsList = [];

  // 퀴즈 모드 (0: 단어->의미, 1: 의미->단어)
  int _quizMode = 0;
  AccentType _selectedAccent = AccentType.american;

  // 퀴즈 결과 화면 표시 여부
  bool _showingResults = false;

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
  }

  @override
  void didUpdateWidget(ModernQuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.words != widget.words) {
      _prepareQuiz();
    }
  }

  void _prepareQuiz() {
    if (widget.words.length < 4) {
      // 퀴즈를 위해 최소 4개의 단어가 필요
      _quizWords = [];
      setState(() {
        _isReady = false;
      });
      return;
    }

    // 퀴즈용 단어 선택 (모든 단어 사용)
    _quizWords = List.from(widget.words);
    _quizWords.shuffle();
    _currentIndex = 0;
    _correctAnswers = 0;
    _totalAnswered = 0;
    _showResult = false;
    _selectedOption = null;
    _wrongAnswers = [];
    _correctWordsList = [];
    _showingResults = false;

    setState(() {
      _isReady = true;
    });

    _prepareQuestion();
  }

  void _prepareQuestion() {
    if (_currentIndex >= _quizWords.length) {
      return;
    }

    // 현재 단어
    final correctWord = _quizWords[_currentIndex];

    List<String> optionsList = [];
    if (_quizMode == 0) {
      // 단어->의미 퀴즈: 정답 의미와 오답 의미 3개 준비

      // 오답 단어 최대 20개 선택 (중복 없이, 현재 단어 제외)
      List<WordEntry> otherWords = widget.allWords
          .where((w) => w.word != correctWord.word && w.meaning.isNotEmpty)
          .toList();

      if (otherWords.length < 3) {
        // 충분한 단어가 없으면 기본 단어 사용
        optionsList = [
          correctWord.meaning,
          "잘못된 의미 1",
          "잘못된 의미 2",
          "잘못된 의미 3",
        ];
      } else {
        otherWords.shuffle();
        otherWords = otherWords.take(3).toList();

        // 정답 의미와 오답 의미 3개 합치기
        optionsList = [correctWord.meaning]
          ..addAll(otherWords.map((w) => w.meaning));
      }
    } else {
      // 의미->단어 퀴즈: 정답 단어와 오답 단어 3개 준비

      // 오답 단어 최대 20개 선택 (중복 없이, 현재 단어 제외)
      List<WordEntry> otherWords =
          widget.allWords.where((w) => w.word != correctWord.word).toList();

      if (otherWords.length < 3) {
        // 충분한 단어가 없으면 기본 단어 사용
        optionsList = [
          correctWord.word,
          "Wrong1",
          "Wrong2",
          "Wrong3",
        ];
      } else {
        otherWords.shuffle();
        otherWords = otherWords.take(3).toList();

        // 정답 단어와 오답 단어 3개 합치기
        optionsList = [correctWord.word]..addAll(otherWords.map((w) => w.word));
      }
    }

    // 보기 섞기
    optionsList.shuffle();

    setState(() {
      _options = optionsList;
      _selectedOption = null;
      _showResult = false;
    });
  }

  void _checkAnswer(String selected) {
    final correctWord = _quizWords[_currentIndex];
    final correctAnswer =
        _quizMode == 0 ? correctWord.meaning : correctWord.word;

    bool isCorrect = selected == correctAnswer;

    setState(() {
      _selectedOption = selected;
      _showResult = true;
      _totalAnswered++;

      if (isCorrect) {
        _correctAnswers++;
        _correctWordsList.add(correctWord);
      } else {
        _wrongAnswers.add(correctWord);
      }
    });

    // 퀴즈 결과 콜백 호출
    widget.onQuizAnswered(correctWord, isCorrect);
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _quizWords.length) {
        _prepareQuestion();
      } else {
        // 모든 문제 완료 - 결과 화면으로 전환
        _showingResults = true;
      }
    });
  }

  void _restartQuiz() {
    _prepareQuiz();
  }

  // 틀린 문제만으로 다시 시작
  void _restartWithMistakes() {
    setState(() {
      if (_wrongAnswers.isNotEmpty) {
        _quizWords = List.from(_wrongAnswers);
        _quizWords.shuffle();
        _currentIndex = 0;
        _correctAnswers = 0;
        _totalAnswered = 0;
        _wrongAnswers = [];
        _correctWordsList = [];
        _showResult = false;
        _selectedOption = null;
        _showingResults = false;
        _prepareQuestion();
      }
    });
  }

  void _toggleQuizMode() {
    setState(() {
      _quizMode = 1 - _quizMode; // 0 -> 1, 1 -> 0
    });
    _restartQuiz();
  }

  void _showAccentMenu() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '발음 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              _buildAccentButton(AccentType.american, '미국식 발음'),
              _buildAccentButton(AccentType.british, '영국식 발음'),
              _buildAccentButton(AccentType.australian, '호주식 발음'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccentButton(AccentType accent, String accentName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedAccent = accent;
        });
        if (_quizMode == 0) {
          // 단어->의미 모드일 때만 발음 재생
          widget.onSpeakWord(_quizWords[_currentIndex].word, accent: accent);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _selectedAccent == accent
              ? (isDarkMode
                  ? Colors.amber.shade900.withOpacity(0.5) // 다크모드 선택됨 배경색
                  : Colors.amber.shade100) // 라이트모드 선택됨 배경색
              : (isDarkMode
                  ? Colors.amber.shade900.withOpacity(0.3) // 다크모드 배경색
                  : Colors.amber.shade50), // 라이트모드 배경색
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAccent == accent
                ? (isDarkMode
                    ? Colors.amber.shade700 // 다크모드 선택됨 테두리
                    : Colors.amber.shade300) // 라이트모드 선택됨 테두리
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up,
              color: _selectedAccent == accent
                  ? (isDarkMode
                      ? Colors.amber.shade300 // 다크모드 선택됨 아이콘
                      : Colors.amber.shade800) // 라이트모드 선택됨 아이콘
                  : (isDarkMode
                      ? Colors.amber.shade400 // 다크모드 아이콘
                      : Colors.amber.shade700), // 라이트모드 아이콘
            ),
            const SizedBox(width: 8),
            Text(
              accentName,
              style: TextStyle(
                color: _selectedAccent == accent
                    ? (isDarkMode
                        ? Colors.amber.shade300 // 다크모드 선택됨 텍스트
                        : Colors.amber.shade800) // 라이트모드 선택됨 텍스트
                    : (isDarkMode
                        ? Colors.amber.shade400 // 다크모드 텍스트
                        : Colors.amber.shade700), // 라이트모드 텍스트
                fontWeight: _selectedAccent == accent
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 빈 상태 UI
  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 햄스터 이모지 사용
          Text(
            '🐹',
            style: TextStyle(fontSize: 72),
          ),
          SizedBox(height: 24),
          Text(
            '퀴즈를 위해 최소 4개의 단어가 필요합니다.',
            style: TextStyle(
                fontSize: 16,
                color:
                    isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              //_tabController.animateTo(0); // 단어 추가 탭으로 이동
            },
            child: Text('단어 추가하기'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: Colors.white,
              backgroundColor:
                  isDarkMode ? Colors.amber.shade700 : Colors.amber.shade600,
            ),
          ),
        ],
      ),
    );
  }

// _buildQuizCompleteScreen 메서드 수정
  Widget _buildQuizCompleteScreen() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final successColor = _correctAnswers > (_totalAnswered / 2)
        ? (isDarkMode ? Colors.amber.shade900 : Colors.amber.shade50)
        : (isDarkMode ? Colors.orange.shade900 : Colors.orange.shade50);

    final successIconColor = _correctAnswers > (_totalAnswered / 2)
        ? (isDarkMode ? Colors.amber.shade300 : Colors.amber.shade600)
        : (isDarkMode ? Colors.orange.shade300 : Colors.orange);

    final successTextColor = _correctAnswers > (_totalAnswered / 2)
        ? (isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700)
        : (isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700);

    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          margin: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black38 : Colors.grey.shade200,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: successColor,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 햄스터 이모지 사용
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: successColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '🐹',
                  style: TextStyle(fontSize: 32),
                ),
              ),
              SizedBox(height: 24),
              Text(
                '퀴즈 완료!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: successColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_correctAnswers / $_totalAnswered 정답',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: successTextColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '정답률: ${(_correctAnswers / _totalAnswered * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: successTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 오답 단어 요약 추가
              if (_wrongAnswers.isNotEmpty) ...[
                SizedBox(height: 24),
                Text(
                  '틀린 단어: ${_wrongAnswers.length}개',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.red.shade900.withOpacity(0.3)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.red.shade700
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _wrongAnswers
                            .take(3)
                            .map((word) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${word.word} : ${word.meaning}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.red.shade300
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ))
                            .toList() +
                        (_wrongAnswers.length > 3
                            ? [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '  ...외 ${_wrongAnswers.length - 3}개',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              ]
                            : []),
                  ),
                ),
                SizedBox(height: 16),
              ],

              SizedBox(height: 24),

              // 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_wrongAnswers.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _restartWithMistakes,
                        icon: Icon(Icons.replay),
                        label: Text('틀린 문제만 다시 풀기'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDarkMode
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                          foregroundColor: isDarkMode
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (_wrongAnswers.isNotEmpty) SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _restartQuiz,
                      icon: Icon(Icons.refresh),
                      label: Text('새로 시작하기'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: isDarkMode
                            ? Colors.amber.shade700
                            : Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 문제 카드 UI
  Widget _buildQuestionCard(
      WordEntry currentWord, String questionTitle, String questionText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.amber.shade800.withOpacity(0.3)
              : Colors.amber.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            questionTitle,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_quizMode == 0) // 단어->의미 모드에서만 발음 버튼 표시
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
          if (_quizMode == 0 && currentWord.pronunciation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: _showAccentMenu,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.amber.shade900.withOpacity(0.3)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentWord.pronunciation,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode
                              ? Colors.amber.shade300
                              : Colors.amber.shade800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: isDarkMode
                            ? Colors.amber.shade300
                            : Colors.amber.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 상단 정보 영역 UI
  Widget _buildInfoHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 문제 번호 컨테이너
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.format_list_numbered,
                  size: 14,
                  color:
                      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
              SizedBox(width: 4),
              Text(
                '${_currentIndex + 1} / ${_quizWords.length}',
                style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade700),
              ),
            ],
          ),
        ),

        // 정답 수 컨테이너
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.amber.shade900.withOpacity(0.3)
                : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🐹', // 햄스터 이모지 사용
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(width: 8),
              Text(
                '정답: $_correctAnswers',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.amber.shade300
                      : Colors.amber.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // 퀴즈 모드 토글 버튼
        InkWell(
          onTap: _toggleQuizMode,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.amber.shade900.withOpacity(0.3)
                  : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  _quizMode == 0 ? '단어→의미' : '의미→단어',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.swap_horiz,
                    size: 14,
                    color: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 보기 버튼 UI
  Widget _buildOptionItem(String option, bool isCorrect, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _showResult ? null : () => _checkAnswer(option),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getOptionColor(isCorrect, isSelected),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getOptionBorderColor(isCorrect, isSelected),
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            option,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected || (isCorrect && _showResult)
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isDarkMode
                  ? (isSelected || (isCorrect && _showResult)
                      ? Colors.white
                      : Colors.grey.shade300)
                  : (isSelected || (isCorrect && _showResult)
                      ? Colors.black
                      : Colors.black87),
            ),
          ),
          trailing: _showResult
              ? _buildResultIcon(isCorrect, isSelected)
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: null,
                ),
        ),
      ),
    );
  }

// 결과 아이콘 UI
  Widget _buildResultIcon(bool isCorrect, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isCorrect) {
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.amber.shade900.withOpacity(0.3)
              : Colors.amber.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
          size: 16,
        ),
      );
    }

    if (isSelected && !isCorrect) {
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.red.shade900.withOpacity(0.3)
              : Colors.red.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          color: isDarkMode ? Colors.red.shade300 : Colors.red,
          size: 16,
        ),
      );
    }

    return SizedBox(width: 24);
  }

  Color _getOptionColor(bool isCorrect, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!_showResult) {
      return isSelected
          ? (isDarkMode
              ? Colors.amber.shade900.withOpacity(0.3)
              : Colors.amber.shade50)
          : Theme.of(context).cardColor;
    }

    if (isCorrect) {
      return isDarkMode
          ? Colors.amber.shade900.withOpacity(0.3)
          : Colors.amber.shade50;
    }

    if (isSelected && !isCorrect) {
      return isDarkMode
          ? Colors.red.shade900.withOpacity(0.3)
          : Colors.red.shade50;
    }

    return Theme.of(context).cardColor;
  }

  Color _getOptionBorderColor(bool isCorrect, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!_showResult) {
      return isSelected
          ? (isDarkMode ? Colors.amber.shade700 : Colors.amber.shade300)
          : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300);
    }

    if (isCorrect) {
      return isDarkMode ? Colors.amber.shade700 : Colors.amber.shade300;
    }

    if (isSelected && !isCorrect) {
      return isDarkMode ? Colors.red.shade700 : Colors.red.shade300;
    }

    return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 퀴즈 준비가 안된 경우
    if (!_isReady) {
      return _buildEmptyState();
    }

    // 퀴즈 완료 화면의 경우 스크롤 가능하게 조정 (이미 수정됨)
    if (_showingResults) {
      return _buildQuizCompleteScreen();
    }

    // 퀴즈 완료
    if (_currentIndex >= _quizWords.length) {
      return _buildQuizCompleteScreen();
    }

    final currentWord = _quizWords[_currentIndex];
    final String questionText = _quizMode == 0
        ? currentWord.word // 단어->의미 모드: 단어를 보여주고 의미 맞추기
        : currentWord.meaning; // 의미->단어 모드: 의미를 보여주고 단어 맞추기
    final String questionTitle =
        _quizMode == 0 ? '다음 단어의 의미는?' : '다음 의미에 해당하는 단어는?';

    final correctAnswer =
        _quizMode == 0 ? currentWord.meaning : currentWord.word;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        // 상단 정보 및 모드 전환 영역
        _buildInfoHeader(),

        // 문제 카드
        _buildQuestionCard(currentWord, questionTitle, questionText),

        // 보기 목록
        Expanded(
          child: ListView.builder(
            itemCount: _options.length,
            shrinkWrap: true, // 내용 크기에 맞게 조정
            padding: EdgeInsets.symmetric(vertical: 8),
            physics: AlwaysScrollableScrollPhysics(), // 항상 스크롤 가능하게 설정
            itemBuilder: (context, index) {
              final option = _options[index];
              bool isCorrect = option == correctAnswer;
              bool isSelected = option == _selectedOption;

              return _buildOptionItem(option, isCorrect, isSelected);
            },
          ),
        ),

        // 하단 버튼
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _showResult
              ? ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text('다음 문제'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.amber.shade700
                        : Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                )
              : null,
        ),
      ]),
    );
  }
}
