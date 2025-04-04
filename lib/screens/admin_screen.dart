import 'package:flutter/material.dart';
import 'package:vocabulary_app/services/purchase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  int _currentCredits = 0;
  bool _isLoading = true;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentCredits();
  }

  @override
  void dispose() {
    _creditsController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCredits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credits = await _purchaseService.getRemainingUsages();
      setState(() {
        _currentCredits = credits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '오류: $e';
      });
    }
  }

  Future<void> _updateCredits() async {
    final creditsToAdd = int.tryParse(_creditsController.text);
    if (creditsToAdd == null) {
      setState(() {
        _statusMessage = '유효한 숫자를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _purchaseService.addUsages(creditsToAdd);

      // 업데이트된 크레딧 다시 로드
      final updatedCredits = await _purchaseService.getRemainingUsages();

      setState(() {
        _currentCredits = updatedCredits;
        _isLoading = false;
        _statusMessage = '$creditsToAdd 크레딧이 추가되었습니다.';
      });

      // 입력 필드 초기화
      _creditsController.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '크레딧 업데이트 중 오류: $e';
      });
    }
  }

  Future<void> _resetCredits() async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('크레딧 초기화'),
        content: Text('정말 크레딧을 0으로 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('초기화'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 크레딧을 가져와서 음수 값으로 추가 (차감)
      final currentCredits = await _purchaseService.getRemainingUsages();
      await _purchaseService.addUsages(-currentCredits);

      setState(() {
        _currentCredits = 0;
        _isLoading = false;
        _statusMessage = '크레딧이 0으로 초기화되었습니다.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '크레딧 초기화 중 오류: $e';
      });
    }
  }

  // 특정 값으로 크레딧 설정
  Future<void> _setCredits(int value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 크레딧을 가져와서 차이값을 계산
      final currentCredits = await _purchaseService.getRemainingUsages();
      final difference = value - currentCredits;

      // 차이값만큼 추가
      await _purchaseService.addUsages(difference);

      setState(() {
        _currentCredits = value;
        _isLoading = false;
        _statusMessage = '크레딧이 $value로 설정되었습니다.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '크레딧 설정 중 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('관리자 설정'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCurrentCredits,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 크레딧 표시
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.shade900.withOpacity(0.3)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.blue.shade800
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: isDarkMode
                              ? Colors.blue.shade300
                              : Colors.blue.shade700,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '현재 사용 가능 횟수',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$_currentCredits회',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 크레딧 추가 섹션
                  Text(
                    '사용 횟수 추가하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _creditsController,
                          decoration: InputDecoration(
                            hintText: '추가할 횟수 입력',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _updateCredits,
                        child: Text('추가'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // 빠른 액션 버튼들
                  Text(
                    '빠른 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickActionButton(10),
                      _buildQuickActionButton(30),
                      _buildQuickActionButton(50),
                      _buildQuickActionButton(100),
                    ],
                  ),

                  SizedBox(height: 24),

                  // 크레딧 초기화 버튼 (위험 액션)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.red.shade900.withOpacity(0.3)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.red.shade800
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '위험 영역',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '이 작업은 되돌릴 수 없습니다.',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.red.shade200
                                : Colors.red.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _resetCredits,
                          icon: Icon(Icons.delete_forever),
                          label: Text('크레딧 초기화 (0으로)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode ? Colors.red.shade900 : Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 상태 메시지
                  if (_statusMessage.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusMessage.contains('오류')
                            ? (isDarkMode
                                ? Colors.red.shade900.withOpacity(0.3)
                                : Colors.red.shade50)
                            : (isDarkMode
                                ? Colors.green.shade900.withOpacity(0.3)
                                : Colors.green.shade50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('오류')
                              ? (isDarkMode
                                  ? Colors.red.shade300
                                  : Colors.red.shade700)
                              : (isDarkMode
                                  ? Colors.green.shade300
                                  : Colors.green.shade700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionButton(int value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () => _setCredits(value),
      icon: Icon(Icons.flash_on),
      label: Text('$value회로 설정'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode
            ? Colors.amber.shade900.withOpacity(0.4)
            : Colors.amber.shade100,
        foregroundColor:
            isDarkMode ? Colors.amber.shade300 : Colors.amber.shade900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
