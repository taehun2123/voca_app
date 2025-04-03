// 모던 디자인의 퀴즈 스크린
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';

class ModernQuizScreen extends StatefulWidget {
  final List<WordEntry> words;
  final List<WordEntry> allWords;
  final Function(String, {AccentType? accent}) onSpeakWord;

  const ModernQuizScreen({
    Key? key,
    required this.words,
    required this.allWords,
    required this.onSpeakWord,
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

  // 퀴즈 모드 (0: 단어->의미, 1: 의미->단어)
  int _quizMode = 0;
  AccentType _selectedAccent = AccentType.american;

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

    setState(() {
      _selectedOption = selected;
      _showResult = true;
      _totalAnswered++;

      if (selected == correctAnswer) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _quizWords.length) {
        _prepareQuestion();
      }
    });
  }

  void _restartQuiz() {
    _prepareQuiz();
  }

  void _toggleQuizMode() {
    setState(() {
      _quizMode = 1 - _quizMode; // 0 -> 1, 1 -> 0
    });
    _restartQuiz();
  }

  void _showAccentMenu() {
    showModalBottomSheet(
      context: context,
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
              ? Colors.blue.shade100
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAccent == accent
                ? Colors.blue.shade300
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up,
              color: _selectedAccent == accent
                  ? Colors.blue.shade800
                  : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              accentName,
              style: TextStyle(
                color: _selectedAccent == accent
                    ? Colors.blue.shade800
                    : Colors.blue.shade700,
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

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 60,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24),
            Text(
              '퀴즈를 위해 최소 4개의 단어가 필요합니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
              ),
            ),
          ],
        ),
      );
    }

    // 퀴즈 완료
    if (_currentIndex >= _quizWords.length) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(24),
          margin: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _correctAnswers > (_totalAnswered / 2)
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _correctAnswers > (_totalAnswered / 2)
                      ? Icons.emoji_events
                      : Icons.school,
                  size: 50,
                  color: _correctAnswers > (_totalAnswered / 2)
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              SizedBox(height: 24),
              Text(
                '퀴즈 완료!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _correctAnswers > (_totalAnswered / 2)
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_correctAnswers / $_totalAnswered 정답',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _correctAnswers > (_totalAnswered / 2)
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '정답률: ${(_correctAnswers / _totalAnswered * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: _correctAnswers > (_totalAnswered / 2)
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _restartQuiz,
                child: Text('다시 시작하기'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = _quizWords[_currentIndex];
    final String questionText = _quizMode == 0
        ? currentWord.word // 단어->의미 모드: 단어를 보여주고 의미 맞추기
        : currentWord.meaning; // 의미->단어 모드: 의미를 보여주고 단어 맞추기
    final String questionTitle =
        _quizMode == 0 ? '다음 단어의 의미는?' : '다음 의미에 해당하는 단어는?';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        // 상단 정보 및 모드 전환 영역
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered,
                      size: 14, color: Colors.grey.shade700),
                  SizedBox(width: 4),
                  Text(
                    '${_currentIndex + 1} / ${_quizWords.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 14),
                  SizedBox(width: 8),
                  Text(
                    '정답: $_correctAnswers',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: _toggleQuizMode,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _quizMode == 0 ? '단어→의미' : '의미→단어',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.swap_horiz,
                            size: 14, color: Colors.purple.shade700),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
// 문제 카드 부분 수정
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // 테마 카드 색상
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).shadowColor.withOpacity(0.1), // 테마 그림자 색상
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                questionTitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade300
                            : Colors.blue,
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade900.withOpacity(0.3)
                            : Colors.blue.shade50,
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
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

// 보기 목록 수정
        Expanded(
          child: ListView.builder(
            itemCount: _options.length,
            padding: EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final option = _options[index];
              final correctAnswer =
                  _quizMode == 0 ? currentWord.meaning : currentWord.word;
              bool isCorrect = option == correctAnswer;
              bool isSelected = option == _selectedOption;

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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected || (isCorrect && _showResult)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Theme.of(context).brightness == Brightness.dark
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
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: null,
                          ),
                  ),
                ),
              );
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  )
                : null),
      ]),
    );
  }
// 다음 메서드들을 ModernQuizScreen 클래스에 추가하거나 업데이트합니다

  Color _getOptionColor(bool isCorrect, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!_showResult) {
      return isSelected
          ? (isDarkMode
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.blue.shade50)
          : Theme.of(context).cardColor;
    }

    if (isCorrect) {
      return isDarkMode
          ? Colors.green.shade900.withOpacity(0.3)
          : Colors.green.shade50;
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
          ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300)
          : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300);
    }

    if (isCorrect) {
      return isDarkMode ? Colors.green.shade700 : Colors.green.shade300;
    }

    if (isSelected && !isCorrect) {
      return isDarkMode ? Colors.red.shade700 : Colors.red.shade300;
    }

    return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  Widget _buildResultIcon(bool isCorrect, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isCorrect) {
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.green.shade900.withOpacity(0.3)
              : Colors.green.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check,
            color: isDarkMode ? Colors.green.shade300 : Colors.green, size: 16),
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
        child: Icon(Icons.close,
            color: isDarkMode ? Colors.red.shade300 : Colors.red, size: 16),
      );
    }

    return SizedBox(width: 24);
  }
}
