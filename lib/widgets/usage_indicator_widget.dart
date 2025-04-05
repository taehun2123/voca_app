// lib/widgets/usage_indicator_widget.dart

import 'package:flutter/material.dart';
import 'package:vocabulary_app/services/purchase_service.dart';

class UsageIndicatorWidget extends StatelessWidget {
  final int remainingUsages;
  final VoidCallback onBuyPressed;

  const UsageIndicatorWidget({
    Key? key,
    required this.remainingUsages,
    required this.onBuyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    // 사용량에 따른 상태 설정
    if (remainingUsages <= 0) {
      statusColor = Colors.red;
      statusText = '사용량 부족';
      statusIcon = Icons.error_outline;
    } else if (remainingUsages <= 3) {
      statusColor = Colors.orange;
      statusText = '부족';
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusColor = Colors.green;
      statusText = '사용 가능';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? statusColor.withOpacity(0.2)
            : statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '남은 사용 횟수: $remainingUsages회',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (remainingUsages <= 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      remainingUsages <= 0
                          ? '단어장을 추가로 생성하려면 충전이 필요합니다.'
                          : '사용량이 얼마 남지 않았습니다. 곧 충전하세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? statusColor.withOpacity(0.9)
                            : statusColor.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (remainingUsages <= 5)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _watchAdForCredits(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.purple.shade900
                        : Colors.purple.shade100,
                    foregroundColor: isDarkMode
                        ? Colors.purple.shade300
                        : Colors.purple.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: Icon(Icons.ondemand_video, size: 16),
                  label: const Text('무료'),
                ),
                ElevatedButton(
                  onPressed: onBuyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('충전하기'),
                ),
              ],
            )
        ],
      ),
    );
  }
    // 광고 시청 메서드 추가
  Future<void> _watchAdForCredits(BuildContext context) async {
    final purchaseService = PurchaseService();
    
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final result = await purchaseService.addCreditByWatchingAd();
      
      // 로딩 다이얼로그 닫기
      Navigator.of(context, rootNavigator: true).pop();
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('광고 시청 완료! 1회 충전되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('광고를 불러올 수 없습니다. 나중에 다시 시도해주세요.'),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('광고 처리 중 오류가 발생했습니다.'),
        ),
      );
    }
  }
}
