// lib/widgets/dialogs/delete_day_dialog.dart
import 'package:flutter/material.dart';

Future<bool> showDeleteDayDialog({
  required BuildContext context,
  required String dayName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          SizedBox(width: 8),
          Text('단어장 삭제'),
        ],
      ),
      content: Text(
          '$dayName 단어장을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며, 해당 단어장의 모든 단어가 삭제됩니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('취소'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('삭제'),
        ),
      ],
    ),
  ).then((value) => value ?? false); // 취소 시 false 반환
}