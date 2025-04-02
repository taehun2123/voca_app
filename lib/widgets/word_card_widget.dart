import 'package:flutter/material.dart';
import '../model/word_entry.dart';
import '../services/tts_service.dart';

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

class _WordCardWidgetState extends State<WordCardWidget> {
  AccentType _selectedAccent = AccentType.american;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0, // 그림자 제거
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // 둥근 모서리
        side: BorderSide(color: Colors.grey.shade200), // 테두리 추가
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '암기완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
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
                    fontFamily: 'Roboto',  // 발음 기호에 적합한 폰트
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            Text(
              widget.word.meaning,
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.grey[900],
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
                if (widget.word.examples.isNotEmpty) ...[
                  const Text(
                    '예문:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.word.examples.map((example) => _buildExampleItem(example)),
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
                  ...widget.word.commonPhrases.map((phrase) => _buildPhraseItem(phrase)),
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

  Widget _buildSpeakMenu() {
    return PopupMenuButton<AccentType>(
      icon: const Icon(Icons.volume_up, color: Colors.blue),
      tooltip: '발음 듣기',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
          color: _selectedAccent == accent ? Colors.blue : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(accentName),
      ],
    );
  }

  Widget _buildExampleItem(String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
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
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            InkWell(
              onTap: () => _showExampleSpeakOptions(example),
              child: Icon(
                Icons.volume_up,
                color: Colors.blue.shade400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhraseItem(String phrase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
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
              ),
            ),
          ),
          InkWell(
            onTap: () => _showExampleSpeakOptions(phrase),
            child: Icon(
              Icons.volume_up,
              color: Colors.grey.shade600,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorizeButton() {
    return GestureDetector(
      onTap: () => widget.onUpdateMemorizedStatus(widget.word.word, !widget.word.isMemorized),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.word.isMemorized ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.word.isMemorized ? Icons.check_circle : Icons.check_circle_outline,
              color: widget.word.isMemorized ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.word.isMemorized ? '암기완료' : '암기하기',
              style: TextStyle(
                color: widget.word.isMemorized ? Colors.green : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExampleSpeakOptions(String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '발음 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volume_up, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              accentName,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}