// lib/widgets/dialogs/duplicate_warning_dialog.dart
import 'package:flutter/material.dart';

/// 중복 단어가 있을 때 표시할 경고 다이얼로그
Future<bool> showDuplicateWarningDialog({
  required BuildContext context,
  required Map<String, List<String>> duplicatesInOtherCollections,
}) async {
  // 전체 중복 단어 수 계산
  int totalDuplicates = 0;
  duplicatesInOtherCollections.forEach((day, words) {
    totalDuplicates += words.length;
  });

  // 중복 단어 정보 텍스트 생성
  String detailText = '';
  duplicatesInOtherCollections.forEach((day, words) {
    // 각 단어장별로 최대 3개 단어만 표시하고 나머지는 '외 N개'로 표시
    String wordsList = words.length <= 3
        ? words.join(', ')
        : '${words.take(3).join(', ')} 외 ${words.length - 3}개';

    detailText += '• $day: $wordsList\n';
  });

  // 다이얼로그로 사용자에게 물어보기
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 다이얼로그 외부 탭으로 닫기 방지
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                ),
                SizedBox(width: 8),
                Text('단어 중복 감지'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다른 단어장에 이미 저장된 단어가 $totalDuplicates개 있습니다:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    detailText,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '중복 추가 시 기존 단어장에서 단어가 제거되고 새 단어장으로 이동합니다.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('건너뛰기'),
                onPressed: () {
                  Navigator.of(context).pop(false); // 중복 단어 건너뛰기
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                child: Text('중복 추가'),
                onPressed: () {
                  Navigator.of(context).pop(true); // 중복 추가 허용
                },
              ),
            ],
          );
        },
      ) ??
      false; // 다이얼로그가 예기치 않게 닫히면 기본값은 건너뛰기(false)
}