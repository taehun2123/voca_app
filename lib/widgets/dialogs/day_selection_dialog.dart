import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';

/// 단어 추가 시 사용할 단어장 선택 다이얼로그
Future<String?> showDaySelectionDialog({
  required BuildContext context,
  required Map<String, List<WordEntry>> dayCollections,
  required int nextDayNum,
}) async {
  final String suggestedDay = 'DAY $nextDayNum';

  // 단어장 모드 선택: 새 단어장 또는 기존 단어장에 추가
  bool createNewCollection = true;
  String selectedExistingDay =
      dayCollections.isNotEmpty ? dayCollections.keys.first : suggestedDay;

  // 컨트롤러는 새 단어장 이름 입력용
  final TextEditingController controller =
      TextEditingController(text: suggestedDay);

  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '단어장 설정',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모드 선택 라디오 버튼
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '새 단어장 만들기',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              leading: Radio<bool>(
                value: true,
                groupValue: createNewCollection,
                onChanged: (value) {
                  setState(() {
                    createNewCollection = value!;
                  });
                },
              ),
            ),

            // 새 단어장 모드일 때 이름 입력 필드
            if (createNewCollection)
              Padding(
                padding: const EdgeInsets.only(left: 30.0, bottom: 8.0),
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: DAY 1',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.white,
                    filled: true,
                  ),
                ),
              ),

            // 기존 단어장 선택 옵션
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '기존 단어장에 추가',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              leading: Radio<bool>(
                value: false,
                groupValue: createNewCollection,
                onChanged: dayCollections.isEmpty
                    ? null // 단어장이 없으면 비활성화
                    : (value) {
                        setState(() {
                          createNewCollection = value!;
                        });
                      },
              ),
            ),

            // 기존 단어장 목록 (기존 단어장 모드일 때만 표시)
            if (!createNewCollection && dayCollections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    color: Theme.of(context).cardColor,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedExistingDay,
                      items: dayCollections.keys.map((String day) {
                        final count = dayCollections[day]?.length ?? 0;
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(day),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blue.shade900.withOpacity(0.3)
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$count단어',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedExistingDay = newValue;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      dropdownColor: Theme.of(context).cardColor,
                    ),
                  ),
                ),
              ),

            // 단어장이 없을 때 메시지
            if (!createNewCollection && dayCollections.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Text(
                  '저장된 단어장이 없습니다.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('취소'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (createNewCollection) {
                // 새 단어장 생성 모드
                Navigator.of(context).pop(controller.text);
              } else {
                // 기존 단어장에 추가 모드
                Navigator.of(context).pop(selectedExistingDay);
              }
            },
            child: Text('확인'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      );
    }),
  );

  // 컨트롤러 정리
  controller.dispose();
  
  return result;
}

// nextDayNum 계산 함수
int calculateNextDayNumber(Map<String, List<WordEntry>> dayCollections) {
  int nextDayNum = 1;

  if (dayCollections.isNotEmpty) {
    try {
      // 유효한 DAY 형식의 키만 필터링
      List<int> validDayNumbers = [];

      for (var day in dayCollections.keys) {
        // 정규식으로 "DAY " 다음에 오는 숫자 추출
        final match = RegExp(r'DAY\s+(\d+)').firstMatch(day);
        if (match != null && match.group(1) != null) {
          validDayNumbers.add(int.parse(match.group(1)!));
        }
      }

      if (validDayNumbers.isNotEmpty) {
        // 가장 큰 DAY 번호 찾기
        nextDayNum = validDayNumbers.reduce((a, b) => a > b ? a : b) + 1;
      }
    } catch (e) {
      print('DAY 번호 계산 중 오류 발생: $e');
      // 오류 발생 시 기본값 1 사용
      nextDayNum = 1;
    }
  }

  return nextDayNum;
}