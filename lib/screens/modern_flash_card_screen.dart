// 모던 디자인의 플래시카드 스크린 (다크모드 개선)
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';

class ModernFlashCardScreen extends StatefulWidget {
  final List<WordEntry> words;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(String)? onReviewComplete;

  const ModernFlashCardScreen({
    Key? key,
    required this.words,
    required this.onSpeakWord,
    this.onReviewComplete,
  }) : super(key: key);

  @override
  _ModernFlashCardScreenState createState() => _ModernFlashCardScreenState();
}

class _ModernFlashCardScreenState extends State<ModernFlashCardScreen> {
  int _currentIndex = 0;
  bool _showMeaning = false;
  List<WordEntry> _shuffledWords = [];
  AccentType _selectedAccent = AccentType.american;

  @override
  void initState() {
    super.initState();
    _initializeWords();
  }

  @override
  void didUpdateWidget(ModernFlashCardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.words != widget.words) {
      _initializeWords();
    }
  }

  void _initializeWords() {
    _shuffledWords = List.from(widget.words);
    _shuffledWords.shuffle();
    _currentIndex = 0;
    _showMeaning = false;
  }

  void _nextCard() {
    if (widget.onReviewComplete != null &&
        _currentIndex < _shuffledWords.length) {
      widget.onReviewComplete!(_shuffledWords[_currentIndex].word);
    }

    setState(() {
      if (_currentIndex < _shuffledWords.length - 1) {
        _currentIndex++;
        _showMeaning = false;
      } else {
        // 모든 카드를 다 봤을 때 다이얼로그 표시
        _showCompletionDialog();
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showMeaning = false;
      }
    });
  }

  void _showCompletionDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              Icons.celebration,
              color: Colors.amber,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              '학습 완료!',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        content: Text(
          '모든 단어를 학습했습니다. 다시 시작하시겠습니까?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('취소'),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shuffledWords.shuffle();
              setState(() {
                _currentIndex = 0;
                _showMeaning = false;
              });
            },
            child: Text('다시 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
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
        widget.onSpeakWord(_shuffledWords[_currentIndex].word, accent: accent);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _selectedAccent == accent
              ? isDarkMode
                  ? Colors.blue.shade900.withOpacity(0.5) // 다크모드 선택됨 배경
                  : Colors.blue.shade100 // 라이트모드 선택됨 배경
              : isDarkMode
                  ? Colors.blue.shade900.withOpacity(0.3) // 다크모드 배경
                  : Colors.blue.shade50, // 라이트모드 배경
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAccent == accent
                ? isDarkMode
                    ? Colors.blue.shade700 // 다크모드 선택됨 테두리
                    : Colors.blue.shade300 // 라이트모드 선택됨 테두리
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up,
              color: _selectedAccent == accent
                  ? isDarkMode
                      ? Colors.blue.shade300 // 다크모드 선택됨 아이콘
                      : Colors.blue.shade800 // 라이트모드 선택됨 아이콘
                  : isDarkMode
                      ? Colors.blue.shade400 // 다크모드 아이콘
                      : Colors.blue.shade700, // 라이트모드 아이콘
            ),
            const SizedBox(width: 8),
            Text(
              accentName,
              style: TextStyle(
                color: _selectedAccent == accent
                    ? isDarkMode
                        ? Colors.blue.shade300 // 다크모드 선택됨 텍스트
                        : Colors.blue.shade800 // 라이트모드 선택됨 텍스트
                    : isDarkMode
                        ? Colors.blue.shade400 // 다크모드 텍스트
                        : Colors.blue.shade700, // 라이트모드 텍스트
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_shuffledWords.isEmpty) {
      return Center(
        child: Text(
          '학습할 단어가 없습니다.',
          style: TextStyle(
            fontSize: 16, 
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
          ),
        ),
      );
    }

    final word = _shuffledWords[_currentIndex];

    return Column(children: [
      // 상단 프로그레스 바 및 정보
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / ${_shuffledWords.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.grey.shade400 // 다크모드 텍스트 색상
                        : Colors.grey.shade700, // 라이트모드 텍스트 색상
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '발음: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade400 // 다크모드 텍스트 색상
                            : Colors.grey.shade700, // 라이트모드 텍스트 색상
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAccentMenu,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blue.shade900.withOpacity(0.3) // 다크모드 배경
                              : Colors.blue.shade50, // 라이트모드 배경
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedAccent == AccentType.american
                                  ? '미국식'
                                  : _selectedAccent == AccentType.british
                                      ? '영국식'
                                      : '호주식',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.blue.shade300 // 다크모드 텍스트 색상
                                    : Colors.blue.shade700, // 라이트모드 텍스트 색상
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: isDarkMode
                                  ? Colors.blue.shade300 // 다크모드 아이콘 색상
                                  : Colors.blue.shade700, // 라이트모드 아이콘 색상
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _shuffledWords.length,
                backgroundColor: isDarkMode
                    ? Colors.grey.shade800 // 다크모드 배경
                    : Colors.grey.shade200, // 라이트모드 배경
                color: isDarkMode
                    ? Colors.blue.shade300 // 다크모드 진행 색상
                    : Colors.blue, // 라이트모드 진행 색상
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
// 플래시카드 영역
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showMeaning = !_showMeaning;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // 테마 카드 색상 사용
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black38
                      : Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 단어 정보
                    Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.color, // 테마 제목 색상
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      word.pronunciation,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),

                    // 발음 듣기 버튼
                    InkWell(
                      onTap: () => widget.onSpeakWord(word.word,
                          accent: _selectedAccent),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blue.shade900.withOpacity(0.3)
                              : Colors.blue.shade50,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black26
                                  : Colors.blue.shade100,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.volume_up,
                          color: isDarkMode
                              ? Colors.blue.shade300
                              : Colors.blue,
                          size: 28,
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // 뜻과 예문 (탭하면 표시)
                    if (_showMeaning) ...[
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        margin: EdgeInsets.symmetric(vertical: 20),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blue.shade900.withOpacity(0.3)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          word.meaning,
                          style: TextStyle(
                            fontSize: 20,
                            color: isDarkMode
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 20),
                      if (word.examples.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.format_quote,
                                    color: isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '예문',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                  Spacer(),
                                  // 예문 발음 듣기 버튼
                                  InkWell(
                                    onTap: () => widget.onSpeakWord(
                                      word.examples.first,
                                      accent: _selectedAccent,
                                    ),
                                    child: Icon(
                                      Icons.volume_up,
                                      color: isDarkMode
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade700,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                word.examples.first,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: isDarkMode
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '탭하여 의미 보기',
                              style: TextStyle(
                                color: isDarkMode
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
// 하단 네비게이션 버튼
      Padding(
        padding: const EdgeInsets.all(30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _currentIndex > 0 ? _previousCard : null,
              icon: Icon(Icons.arrow_back),
              label: Text('이전'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? Colors.grey.shade800 // 다크모드 배경색
                    : Colors.grey.shade200, // 라이트모드 배경색
                foregroundColor: isDarkMode
                    ? Colors.grey.shade200 // 다크모드 텍스트/아이콘 색상
                    : Colors.black87, // 라이트모드 텍스트/아이콘 색상
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: isDarkMode
                        ? Colors.grey.shade900 // 다크모드 비활성화 배경색
                        : Colors.grey.shade100, // 라이트모드 비활성화 배경색
                disabledForegroundColor: isDarkMode
                        ? Colors.grey.shade700 // 다크모드 비활성화 텍스트/아이콘 색상
                        : Colors.grey.shade400, // 라이트모드 비활성화 텍스트/아이콘 색상
              ),
            ),
            ElevatedButton.icon(
              onPressed: _nextCard,
              icon: Icon(Icons.arrow_forward),
              label: Text('다음'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? Colors.blue.shade800 // 다크모드 배경색
                    : Colors.blue, // 라이트모드 배경색
                foregroundColor: Colors.white, // 텍스트/아이콘 색상 (모든 모드에서 흰색)
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      )
    ]);
  }
}