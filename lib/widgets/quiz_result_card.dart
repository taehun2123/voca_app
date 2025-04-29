// lib/widgets/quiz_result_card.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';

class QuizResultCard extends StatelessWidget {
  final WordEntry word;
  final bool isCorrect;
  final bool isPartiallyCorrect;
  final Function(String, {AccentType? accent}) onSpeakWord;

  const QuizResultCard({
    Key? key,
    required this.word,
    required this.isCorrect,
    required this.isPartiallyCorrect,
    required this.onSpeakWord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 상태에 따른 색상 설정
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData statusIcon;
    String statusText;
    
    if (isCorrect) {
      bgColor = isDarkMode ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50;
      borderColor = isDarkMode ? Colors.green.shade700 : Colors.green.shade300;
      textColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
      statusIcon = Icons.check_circle;
      statusText = '정답';
    } else if (isPartiallyCorrect) {
      bgColor = isDarkMode ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50;
      borderColor = isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300;
      textColor = isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
      statusIcon = Icons.remove_circle;
      statusText = '부분 정답';
    } else {
      bgColor = isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
      borderColor = isDarkMode ? Colors.red.shade700 : Colors.red.shade300;
      textColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
      statusIcon = Icons.cancel;
      statusText = '오답';
    }
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
      color: bgColor,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              statusIcon,
              color: textColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                word.word,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? textColor.withOpacity(0.2)
                    : textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          word.meaning,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.volume_up,
            color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
          ),
          onPressed: () => onSpeakWord(word.word),
          tooltip: '발음 듣기',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (word.pronunciation.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        '발음: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        word.pronunciation,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                
                if (word.examples.isNotEmpty) ...[
                  Divider(),
                  Text(
                    '예문:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  ...word.examples.map((example) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• $example',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  )),
                ],
                
                if (word.commonPhrases.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Divider(),
                  Text(
                    '기출 표현:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  ...word.commonPhrases.map((phrase) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• $phrase',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}