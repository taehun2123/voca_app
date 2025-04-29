import 'package:flutter/material.dart';
import '../model/word_entry.dart';
import '../services/tts_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:percent_indicator/percent_indicator.dart';

class WordCardWidget extends StatefulWidget {
  final WordEntry word;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(String, bool) onUpdateMemorizedStatus;

  const WordCardWidget({
    Key? key,
    required this.word,
    required this.onSpeakWord,
    required this.onUpdateMemorizedStatus,
  }) : super(key: key);

  @override
  State<WordCardWidget> createState() => _WordCardWidgetState();
}

class AnimatedWordCard extends StatelessWidget {
  final WordEntry word;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(String, bool) onUpdateMemorizedStatus;
  final int index;

  const AnimatedWordCard({
    Key? key,
    required this.word,
    required this.onSpeakWord,
    required this.onUpdateMemorizedStatus,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: WordCardWidget(
            word: word,
            onSpeakWord: onSpeakWord,
            onUpdateMemorizedStatus: onUpdateMemorizedStatus,
          ),
        ),
      ),
    );
  }
}

class _WordCardWidgetState extends State<WordCardWidget> {
  AccentType _selectedAccent = AccentType.american;

  @override
  Widget build(BuildContext context) {
    // 테마 색상 지원
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0, // 그림자 제거
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // 둥근 모서리
        side: BorderSide(
            color: isDarkMode
                ? Colors.amber.shade600
                : Colors.amber.shade200), // 테마에 맞는 테두리
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() {});
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.word.word,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            _buildSpeakMenu(),
            if (widget.word.isMemorized)
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.amber.shade900.withOpacity(0.3)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color:
                            isDarkMode ? Colors.amber.shade300 : Colors.amber,
                        size: 14),
                    SizedBox(width: 4),
                    Text(
                      '암기완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.amber.shade300
                            : Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.word.pronunciation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Text(
                  widget.word.pronunciation,
                  style: TextStyle(
                    fontFamily: 'Roboto', // 발음 기호에 적합한 폰트
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey[700],
                  ),
                ),
              ),
            Text(
              widget.word.meaning,
              style: TextStyle(
                fontSize: 15.0,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 퀴즈 및 학습 통계 추가
                _buildStatisticsSection(),
                SizedBox(height: 16),
                if (widget.word.examples.isNotEmpty) ...[
                  const Text(
                    '예문:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.word.examples
                      .map((example) => _buildExampleItem(example)),
                  const SizedBox(height: 16),
                ],
                if (widget.word.commonPhrases.isNotEmpty) ...[
                  const Text(
                    '기출 표현:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.word.commonPhrases
                      .map((phrase) => _buildPhraseItem(phrase)),
                  const SizedBox(height: 16),
                ],
                // 암기 버튼
                _buildMemorizeButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

    // 통계 정보 섹션 추가
  Widget _buildStatisticsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 퀴즈 정답률 계산
    double correctRate = widget.word.quizAttempts > 0 
        ? widget.word.quizCorrect / widget.word.quizAttempts 
        : 0.0;
    
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey.shade800 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '학습 통계',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode 
                  ? Colors.grey.shade300 
                  : Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 복습 횟수
              _buildStatItem(
                label: '복습 횟수',
                value: '${widget.word.reviewCount}회',
                icon: Icons.refresh,
                color: Colors.blue,
              ),
              
              // 난이도 표시
              _buildStatItem(
                label: '난이도',
                value: _getDifficultyText(widget.word.difficulty),
                icon: Icons.trending_up,
                color: _getDifficultyColor(widget.word.difficulty),
              ),
              
              // 퀴즈 정답률
              _buildQuizRateIndicator(correctRate),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isDarkMode 
                  ? color.shade300 
                  : color.shade700,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode 
                    ? Colors.grey.shade400 
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode 
                ? color.shade300 
                : color.shade700,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuizRateIndicator(double rate) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 정답률에 따른 색상
    Color color;
    if (rate >= 0.8) {
      color = Colors.green;
    } else if (rate >= 0.5) {
      color = Colors.amber;
    } else {
      color = Colors.red;
    }
    
    return Column(
      children: [
        Text(
          '정답률',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode 
                ? Colors.grey.shade400 
                : Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        CircularPercentIndicator(
          radius: 24.0,
          lineWidth: 4.0,
          percent: rate,
          center: Text(
            '${(rate * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDarkMode 
                  ? Colors.white 
                  : Colors.black87,
            ),
          ),
          progressColor: isDarkMode 
              ? color.withOpacity(0.7) 
              : color,
          backgroundColor: isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade300,
        ),
        SizedBox(height: 4),
        Text(
          widget.word.quizAttempts > 0 
              ? '${widget.word.quizCorrect}/${widget.word.quizAttempts}' 
              : '0/0',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode 
                ? Colors.grey.shade400 
                : Colors.grey.shade600,
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
  
  MaterialColor _getDifficultyColor(double difficulty) {
    if (difficulty >= 0.8) return Colors.red;
    if (difficulty >= 0.4) return Colors.amber;
    return Colors.green;
  }

  Widget _buildSpeakMenu() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<AccentType>(
      icon: Icon(
        Icons.volume_up,
        color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
      ),
      tooltip: '발음 듣기',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor, // 팝업 메뉴 배경색
      onSelected: (AccentType accent) {
        setState(() {
          _selectedAccent = accent;
        });
        widget.onSpeakWord(widget.word.word, accent: accent);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AccentType.american,
          child: _buildAccentMenuItem(AccentType.american),
        ),
        PopupMenuItem(
          value: AccentType.british,
          child: _buildAccentMenuItem(AccentType.british),
        ),
        PopupMenuItem(
          value: AccentType.australian,
          child: _buildAccentMenuItem(AccentType.australian),
        ),
      ],
    );
  }

  Widget _buildAccentMenuItem(AccentType accent) {
    String accentName = '';
    IconData iconData = Icons.language;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (accent) {
      case AccentType.american:
        accentName = '미국식 발음';
        iconData = Icons.language;
        break;
      case AccentType.british:
        accentName = '영국식 발음';
        iconData = Icons.language;
        break;
      case AccentType.australian:
        accentName = '호주식 발음';
        iconData = Icons.language;
        break;
    }

    return Row(
      children: [
        Icon(
          iconData,
          color: _selectedAccent == accent
              ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
              : (isDarkMode ? Colors.grey.shade400 : Colors.grey),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          accentName,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleItem(String example) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue.shade900.withOpacity(0.3)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                example,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color:
                      isDarkMode ? Colors.blue.shade100 : Colors.blue.shade900,
                ),
              ),
            ),
            InkWell(
              onTap: () => _showExampleSpeakOptions(example),
              child: Icon(
                Icons.volume_up,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhraseItem(String phrase) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              phrase,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          InkWell(
            onTap: () => _showExampleSpeakOptions(phrase),
            child: Icon(
              Icons.volume_up,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorizeButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => widget.onUpdateMemorizedStatus(
          widget.word.word, !widget.word.isMemorized),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.word.isMemorized
              ? (isDarkMode
                  ? Colors.amber.shade900.withOpacity(0.3)
                  : Colors.amber.shade50)
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.word.isMemorized
                ? (isDarkMode ? Colors.amber.shade700 : Colors.amber.shade300)
                : Colors.transparent,
            width: widget.word.isMemorized ? 1 : 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.word.isMemorized
                ? Text(
                    '🐹', // 햄스터 이모지 사용
                    style: TextStyle(fontSize: 16),
                  )
                : Icon(
                    Icons.check_circle_outline,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                    size: 20,
                  ),
            const SizedBox(width: 8),
            Text(
              widget.word.isMemorized ? '암기완료' : '암기하기',
              style: TextStyle(
                color: widget.word.isMemorized
                    ? (isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700)
                    : (isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade700),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExampleSpeakOptions(String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // 바텀시트 배경색
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              const SizedBox(height: 16),
              _buildAccentButton(text, AccentType.american, '미국식 발음'),
              _buildAccentButton(text, AccentType.british, '영국식 발음'),
              _buildAccentButton(text, AccentType.australian, '호주식 발음'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccentButton(String text, AccentType accent, String accentName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onSpeakWord(text, accent: accent);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              accentName,
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
