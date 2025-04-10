// lib/widgets/dialogs/day_selection_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';

class DaySelectionBottomSheet extends StatefulWidget {
  final Map<String, List<WordEntry>> dayCollections;
  final String currentDay;
  final Function(String) onDaySelected;
  final Function(String) onEditDayWords;
  final VoidCallback onCreateNewDay;

  const DaySelectionBottomSheet({
    Key? key,
    required this.dayCollections,
    required this.currentDay,
    required this.onDaySelected,
    required this.onEditDayWords,
    required this.onCreateNewDay,
  }) : super(key: key);

  @override
  State<DaySelectionBottomSheet> createState() => _DaySelectionBottomSheetState();
}

class _DaySelectionBottomSheetState extends State<DaySelectionBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade600
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '단어장 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onCreateNewDay();
                  },
                  tooltip: '새 단어장',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue.shade300
                      : Colors.blue,
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.dayCollections.length,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final day = widget.dayCollections.keys.elementAt(index);
                final isSelected = day == widget.currentDay;
                final count = widget.dayCollections[day]?.length ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.onDaySelected(day);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blue.shade900.withOpacity(0.3)
                                  : Colors.blue.shade50)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade700
                                    : Colors.blue.shade300)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 체크 아이콘 (선택된 항목)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.blue.shade800
                                        : Colors.blue)
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200),
                                shape: BoxShape.circle,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected
                                          ? (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.blue.shade300
                                              : Colors.blue.shade800)
                                          : Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  if (count > 0)
                                    Text(
                                      '${count}개 단어',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onEditDayWords(day);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '수정',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 바텀시트를 표시하는 함수
void showDaySelectionBottomSheet({
  required BuildContext context,
  required Map<String, List<WordEntry>> dayCollections,
  required String currentDay,
  required Function(String) onDaySelected,
  required Function(String) onEditDayWords,
  required VoidCallback onCreateNewDay,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DaySelectionBottomSheet(
      dayCollections: dayCollections,
      currentDay: currentDay,
      onDaySelected: onDaySelected,
      onEditDayWords: onEditDayWords,
      onCreateNewDay: onCreateNewDay,
    ),
  );
}