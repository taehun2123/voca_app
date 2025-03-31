import 'package:flutter/material.dart';
import '../model/word_entry.dart';

class QuizScreen extends StatefulWidget {
  final List<WordEntry> words;
  final List<WordEntry> allWords;
  final Function(String) onSpeakWord;

  const QuizScreen({
    Key? key,
    required this.words,
    required this.allWords,
    required this.onSpeakWord,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
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

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
  }

  @override
  void didUpdateWidget(QuizScreen oldWidget) {
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
      List<WordEntry> otherWords = widget.allWords
          .where((w) => w.word != correctWord.word)
          .toList();
      
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
        optionsList = [correctWord.word]
            ..addAll(otherWords.map((w) => w.word));
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
    final correctAnswer = _quizMode == 0 ? correctWord.meaning : correctWord.word;
    
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

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Center(child: Text('퀴즈를 위해 최소 4개의 단어가 필요합니다.'));
    }

    // 퀴즈 완료
    if (_currentIndex >= _quizWords.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '퀴즈 완료!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '$_correctAnswers / $_totalAnswered 정답',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              '정답률: ${(_correctAnswers / _totalAnswered * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _restartQuiz,
              child: Text('다시 시작하기'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      );
    }

    final currentWord = _quizWords[_currentIndex];
    final String questionText = _quizMode == 0 
        ? currentWord.word  // 단어->의미 모드: 단어를 보여주고 의미 맞추기
        : currentWord.meaning; // 의미->단어 모드: 의미를 보여주고 단어 맞추기
    final String questionTitle = _quizMode == 0 
        ? '다음 단어의 의미는?' 
        : '다음 의미에 해당하는 단어는?';
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${_quizWords.length}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Text('모드: '),
                      TextButton(
                        onPressed: _toggleQuizMode,
                        child: Text(_quizMode == 0 ? '단어→의미' : '의미→단어'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '정답: $_correctAnswers',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  questionTitle,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        questionText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_quizMode == 0) // 단어->의미 모드에서만 발음 버튼 표시
                      IconButton(
                        icon: Icon(Icons.volume_up),
                        onPressed: () => widget.onSpeakWord(currentWord.word),
                        tooltip: '발음 듣기',
                      ),
                  ],
                ),
                if (_quizMode == 0)
                  Text(
                    currentWord.pronunciation,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _options.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final option = _options[index];
              final correctAnswer = _quizMode == 0 ? currentWord.meaning : currentWord.word;
              bool isCorrect = option == correctAnswer;
              bool isSelected = option == _selectedOption;
              
              return Card(
                elevation: isSelected ? 4 : 1,
                margin: EdgeInsets.only(bottom: 12),
                color: _showResult
                    ? isCorrect
                        ? Colors.green[100]
                        : isSelected
                            ? Colors.red[100]
                            : null
                    : null,
                child: ListTile(
                  title: Text(option),
                  onTap: _showResult ? null : () => _checkAnswer(option),
                  trailing: _showResult && isCorrect
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : _showResult && isSelected && !isCorrect
                          ? Icon(Icons.close, color: Colors.red)
                          : null,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _showResult
              ? ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text('다음 문제'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                )
              : Text('답을 선택하세요'),
        ),
      ],
    );
  }
}