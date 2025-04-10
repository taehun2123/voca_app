// lib/widgets/dialogs/new_day_dialog.dart
import 'package:flutter/material.dart';

Future<String?> showNewDayDialog({
  required BuildContext context,
  required int nextDayNum,
}) {
  final String suggestedDay = 'DAY $nextDayNum';
  final TextEditingController controller = TextEditingController(text: suggestedDay);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          Icon(
            Icons.create_new_folder,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade300
                : Colors.green,
            size: 24,
          ),
          SizedBox(width: 10),
          Text(
            '새 단어장 만들기',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '새 단어장 이름을 입력하세요',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 16),
          TextField(
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.white,
              filled: true,
              prefixIcon: Icon(Icons.folder_open),
            ),
            autofocus: true,
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final newDayName = controller.text.trim();
            if (newDayName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('단어장 이름을 입력해주세요'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            Navigator.of(context).pop(newDayName);
          },
          child: Text('생성'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade700
                : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: 0,
          ),
        ),
      ],
    ),
  );
}