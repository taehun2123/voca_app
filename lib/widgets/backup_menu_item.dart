// lib/widgets/backup_menu_item.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/screens/backup_screen.dart';

class BackupMenuItem extends StatelessWidget {
  const BackupMenuItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        Icons.cloud_sync,
        color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
      ),
      title: Text('백업 및 복원'),
      subtitle: Text('Google Drive로 데이터 백업/복원'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BackupScreen()),
        );
      },
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}