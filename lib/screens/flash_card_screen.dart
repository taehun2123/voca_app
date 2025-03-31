import 'package:flutter/material.dart';
import '../model/word_entry.dart';

class FlashCardScreen extends StatefulWidget {
  final List<WordEntry> words;
  final Function(String) onSpeakWord;
  final Function(String)? onReviewComplete;

  const FlashCardScreen({
    Key? key,
    required this.words,
    required this.onSpeakWord,
    this.onReviewComplete,
  }) : super(key: key);

  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  int _currentIndex = 0;
  bool _showMeaning = false;
  List<WordEntry> _shuffledWords = [];

  @override
  void initState() {
    super.initState();
    _initializeWords();
  }

  @override
  void didUpdateWidget(FlashCardScreen oldWidget) {
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
    if (widget.onReviewComplete != null && _currentIndex < _shuffledWords.length) {
      widget.onReviewComplete!(_shuffledWords[_currentIndex].word);
    }
    
    setState(() {
      if (_currentIndex < _shuffledWords.length - 1) {
        _currentIndex++;
        _showMeaning = false;
      } else {
        // 모든 카드를 다 봤으면 다시 섞기
        _shuffledWords.shuffle();
        _currentIndex = 0;
        _showMeaning = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모든 단어를 확인했습니다. 다시 시작합니다.')),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_shuffledWords.isEmpty) {
      return Center(child: Text('학습할 단어가 없습니다.'));
    }

    final word = _shuffledWords[_currentIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${_currentIndex + 1} / ${_shuffledWords.length}',
            style: TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showMeaning = !_showMeaning;
              });
            },
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      word.pronunciation,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up),
                      onPressed: () => widget.onSpeakWord(word.word),
                      tooltip: '발음 듣기',
                    ),
                    SizedBox(height: 30),
                    if (_showMeaning) ...[
                      Divider(),
                      SizedBox(height: 20),
                      Text(
                        word.meaning,
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      if (word.examples.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            word.examples.first,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ] else
                      Text(
                        '탭하여 의미 보기',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _previousCard,
                icon: Icon(Icons.arrow_back),
                label: Text('이전'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _nextCard,
                icon: Icon(Icons.arrow_forward),
                label: Text('다음'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}