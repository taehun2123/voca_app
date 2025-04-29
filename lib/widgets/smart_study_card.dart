// lib/widgets/smart_study_card.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';

class SmartStudyCard extends StatefulWidget {
  final WordEntry word;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final VoidCallback onMemorized;
  final Function(bool) onQuizAnswered;
  final MaterialColor color;

  const SmartStudyCard({
    Key? key,
    required this.word,
    required this.onSpeakWord,
    required this.onMemorized,
    required this.onQuizAnswered,
    required this.color,
  }) : super(key: key);

  @override
  _SmartStudyCardState createState() => _SmartStudyCardState();
}

class _SmartStudyCardState extends State<SmartStudyCard> {
  bool _showMeaning = false;
  bool _showQuiz = false;
  bool _answerChecked = false;
  bool _isCorrect = false;
  
  TextEditingController _answerController = TextEditingController();
  AccentType _selectedAccent = AccentType.american;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _toggleMeaning() {
    setState(() {
      _showMeaning = !_showMeaning;
      if (!_showMeaning) {
        _showQuiz = false;
        _answerChecked = false;
        _answerController.clear();
      }
    });
  }

  void _startQuiz() {
    setState(() {
      _showQuiz = true;
      _answerChecked = false;
      _answerController.clear();
    });
  }

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
    final correctAnswer = widget.word.meaning.toLowerCase();

    // 정답 체크 - 의미는 여러 가지 표현이 있을 수 있으므로 포함 관계 확인
    final meaningKeywords = _extractKeywords(correctAnswer);
    final userAnswerKeywords = _extractKeywords(userAnswer);

    // 모든 키워드가 있는지 또는 일부만 있는지 확인
    final matchedKeywords = meaningKeywords.where(
      (keyword) => userAnswerKeywords.any(
        (userKeyword) => userKeyword.contains(keyword) || keyword.contains(userKeyword)
      )
    ).toList();

    bool isCorrect = matchedKeywords.length == meaningKeywords.length;
    bool isPartiallyCorrect = matchedKeywords.isNotEmpty && matchedKeywords.length < meaningKeywords.length;

    setState(() {
      _answerChecked = true;
      _isCorrect = isCorrect;
    });

    // 퀴즈 결과 업데이트 콜백 호출
    widget.onQuizAnswered(isCorrect);
  }

  // 문자열에서 키워드 추출
  List<String> _extractKeywords(String text) {
    // 특수문자 및 구두점 제거
    String cleaned = text.replaceAll(RegExp(r'[^\w\s]'), '');
    
    // 의미없는 단어들 제거 (조사, 관사 등)
    List<String> stopWords = ['은', '는', '이', '가', '을', '를', '에', '의', '로', '으로', 'a', 'an', 'the', 'to', 'in', 'on', 'of', 'for'];
    
    // 단어로 분리하고 필터링
    List<String> words = cleaned.toLowerCase().split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !stopWords.contains(word))
        .toList();
    
    return words;
  }

  void _resetQuiz() {
    setState(() {
      _showQuiz = false;
      _answerChecked = false;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 카드 색상 설정
    Color bgColor = isDarkMode
        ? widget.color.shade900.withOpacity(0.3)
        : widget.color.shade50;
    Color borderColor = isDarkMode
        ? widget.color.shade700
        : widget.color.shade200;
    Color accentColor = isDarkMode
        ? widget.color.shade300
        : widget.color.shade700;
        
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      color: bgColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단어 헤더 영역
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.word.word,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (widget.word.pronunciation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            widget.word.pronunciation,
                            style: TextStyle(
                              fontSize: 14,
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
                // 발음 듣기 버튼
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: accentColor,
                  ),
                  onPressed: () => widget.onSpeakWord(widget.word.word, accent: _selectedAccent),
                  tooltip: '발음 듣기',
                ),
                // 암기 버튼
                IconButton(
                  icon: Icon(
                    widget.word.isMemorized ? Icons.check_circle : Icons.check_circle_outline,
                    color: widget.word.isMemorized
                        ? Colors.green.shade300
                        : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: widget.onMemorized,
                  tooltip: widget.word.isMemorized ? '암기 완료' : '암기하기',
                ),
              ],
            ),
            
            // 통계 영역 - 간략하게 퀴즈 정답률과 난이도만 표시
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    context: context,
                    label: '복습 횟수',
                    value: '${widget.word.reviewCount}회',
                    icon: Icons.refresh,
                  ),
                  _buildMiniStat(
                    context: context,
                    label: '정답률',
                    value: widget.word.quizAttempts > 0
                        ? '${(widget.word.quizCorrect / widget.word.quizAttempts * 100).toInt()}%'
                        : '0%',
                    icon: Icons.poll,
                  ),
                  _buildMiniStat(
                    context: context,
                    label: '난이도',
                    value: _getDifficultyText(widget.word.difficulty),
                    icon: Icons.trending_up,
                  ),
                ],
              ),
            ),
            
            // 뜻 보기/숨기기 버튼
            GestureDetector(
              onTap: _toggleMeaning,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showMeaning ? Icons.visibility_off : Icons.visibility,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _showMeaning ? '뜻 숨기기' : '뜻 보기',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 뜻 영역 (토글로 표시/숨김)
            if (_showMeaning && !_showQuiz) ...[
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? widget.color.shade800.withOpacity(0.3)
                      : widget.color.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '뜻',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.word.meaning,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (widget.word.examples.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        '예문',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.word.examples.first,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 퀴즈 시작 버튼
              if (!_showQuiz)
                TextButton.icon(
                  onPressed: _startQuiz,
                  icon: Icon(Icons.quiz),
                  label: Text('퀴즈 풀기'),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
            ],
            
            // 퀴즈 영역
            if (_showQuiz) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? widget.color.shade800.withOpacity(0.3)
                      : widget.color.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이 단어의 뜻을 입력하세요',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    if (!_answerChecked) ...[
                      TextField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          hintText: '뜻을 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.white,
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        child: Text('정답 확인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDarkMode
                              ? Colors.black
                              : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 정답 결과 표시
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? (isDarkMode
                                  ? Colors.green.shade900.withOpacity(0.3)
                                  : Colors.green.shade50)
                              : (isDarkMode
                                  ? Colors.red.shade900.withOpacity(0.3)
                                  : Colors.red.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect
                                ? (isDarkMode
                                    ? Colors.green.shade700
                                    : Colors.green.shade300)
                                : (isDarkMode
                                    ? Colors.red.shade700
                                    : Colors.red.shade300),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isCorrect
                                      ? (isDarkMode
                                          ? Colors.green.shade300
                                          : Colors.green.shade700)
                                      : (isDarkMode
                                          ? Colors.red.shade300
                                          : Colors.red.shade700),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _isCorrect ? '정답입니다!' : '오답입니다',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect
                                        ? (isDarkMode
                                            ? Colors.green.shade300
                                            : Colors.green.shade700)
                                        : (isDarkMode
                                            ? Colors.red.shade300
                                            : Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '정답: ${widget.word.meaning}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '입력한 답: ${_answerController.text}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetQuiz,
                              child: Text('돌아가기'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColor,
                                side: BorderSide(color: accentColor),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onMemorized,
                              child: Text(
                                widget.word.isMemorized
                                    ? '암기 취소'
                                    : '암기 완료',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.word.isMemorized
                                    ? (isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)
                                    : (isDarkMode
                                        ? Colors.green.shade700
                                        : Colors.green),
                                foregroundColor: isDarkMode
                                    ? Colors.white
                                    : (widget.word.isMemorized
                                        ? Colors.black87
                                        : Colors.white),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMiniStat({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isDarkMode
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  String _getDifficultyText(double difficulty) {
    if (difficulty >= 0.8) return '상';
    if (difficulty >= 0.4) return '중';
    return '하';
  }
}