import 'package:flutter/material.dart';
import '../model/word_entry.dart';

class WordCardWidget extends StatelessWidget {
  final WordEntry word;
  final Function(String) onSpeakWord;
  final Function(String, bool) onUpdateMemorizedStatus;

  const WordCardWidget({
    Key? key,
    required this.word,
    required this.onSpeakWord,
    required this.onUpdateMemorizedStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                word.word,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            IconButton(
              icon: Icon(Icons.volume_up),
              onPressed: () => onSpeakWord(word.word),
              tooltip: '발음 듣기',
            ),
            if (word.isMemorized)
              Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word.pronunciation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                child: Text(
                  word.pronunciation,
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
              word.meaning,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (word.examples.isNotEmpty) ...[
                  const Text(
                    '예문:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ...word.examples.map((example) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '• $example',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      )),
                  const SizedBox(height: 10),
                ],
                if (word.commonPhrases.isNotEmpty) ...[
                  const Text(
                    '기출 표현:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ...word.commonPhrases.map((phrase) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '• $phrase',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      )),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(word.isMemorized ? Icons.check_circle : Icons.check_circle_outline),
                      label: Text(word.isMemorized ? '암기완료' : '암기하기'),
                      onPressed: () => onUpdateMemorizedStatus(word.word, !word.isMemorized),
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                          word.isMemorized ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}