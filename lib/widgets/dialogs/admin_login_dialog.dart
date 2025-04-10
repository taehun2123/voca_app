// lib/widgets/dialogs/admin_login_dialog.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/services/remote_config_service.dart';

Future<void> showAdminLoginDialog({
  required BuildContext context,
  required Function() onSuccess,
}) async {
  final TextEditingController passwordController = TextEditingController();
  final RemoteConfigService remoteConfigService = RemoteConfigService();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text('관리자 인증'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('관리자 모드에 접근하려면 비밀번호를 입력하세요.'),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (remoteConfigService.verifyAdminPassword(passwordController.text)) {
              Navigator.of(context).pop(true);
            } else {
              // 비밀번호 불일치
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('비밀번호가 일치하지 않습니다.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            // 항상 컨트롤러 비우기
            passwordController.clear();
          },
          child: Text('로그인'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );

  // 컨트롤러 정리
  passwordController.dispose();

  // 성공 시 관리자 화면으로 이동
  if (result == true) {
    onSuccess();
  }
}