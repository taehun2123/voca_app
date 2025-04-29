// lib/screens/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocabulary_app/services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  List<Map<String, dynamic>> _backups = [];
  DateTime? _lastBackupTime;
  String? _lastBackupName;
  String? _userName;
  String? _userEmail;
  
  final TextEditingController _backupNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  
  @override
  void dispose() {
    _backupNameController.dispose();
    super.dispose();
  }
  
  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 로그인 상태 확인
      _isAuthenticated = await _backupService.isSignedIn();
      
      if (_isAuthenticated) {
        // 사용자 정보 가져오기
        final user = await _backupService.getCurrentUser();
        if (user != null) {
          _userName = user.displayName;
          _userEmail = user.email;
        }
        
        // 백업 목록 로드
        await _loadBackups();
        
        // 마지막 백업 시간 확인
        _lastBackupTime = await _backupService.getLastBackupTime();
        _lastBackupName = await _backupService.getLastBackupName();
      }
    } catch (e) {
      print('상태 확인 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 로그인 처리
  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _backupService.signIn();
      
      if (success) {
        _isAuthenticated = true;
        
        // 사용자 정보 가져오기
        final user = await _backupService.getCurrentUser();
        if (user != null) {
          _userName = user.displayName;
          _userEmail = user.email;
        }
        
        // 백업 목록 로드
        await _loadBackups();
        
        // 마지막 백업 시간 확인
        _lastBackupTime = await _backupService.getLastBackupTime();
        _lastBackupName = await _backupService.getLastBackupName();
      } else {
        _showErrorSnackBar('Google 로그인에 실패했습니다.');
      }
    } catch (e) {
      print('로그인 오류: $e');
      _showErrorSnackBar('로그인 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 로그아웃 처리
  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _backupService.signOut();
      
      setState(() {
        _isAuthenticated = false;
        _userName = null;
        _userEmail = null;
        _backups = [];
      });
    } catch (e) {
      print('로그아웃 오류: $e');
      _showErrorSnackBar('로그아웃 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 백업 목록 로드
  Future<void> _loadBackups() async {
    if (!_isAuthenticated) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final backups = await _backupService.getBackupsList();
      setState(() {
        _backups = backups;
      });
    } catch (e) {
      print('백업 목록 로드 오류: $e');
      _showErrorSnackBar('백업 목록을 가져오는 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 백업 생성
  Future<void> _createBackup() async {
    if (!_isAuthenticated) {
      _showErrorSnackBar('먼저 로그인해주세요.');
      return;
    }
    
    // 백업 이름 입력 다이얼로그 표시
    await _showBackupNameDialog();
    
    // 다이얼로그에서 취소했으면 종료
    if (_backupNameController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customName = _backupNameController.text.trim();
      final success = await _backupService.createBackup(
        customName: customName.isNotEmpty ? customName : null
      );
      
      if (success) {
        // 백업 리스트 다시 로드
        await _loadBackups();
        
        // 마지막 백업 시간 갱신
        _lastBackupTime = await _backupService.getLastBackupTime();
        _lastBackupName = await _backupService.getLastBackupName();
        
        _showSuccessSnackBar('백업이 성공적으로 생성되었습니다.');
      } else {
        _showErrorSnackBar('백업 생성에 실패했습니다.');
      }
    } catch (e) {
      print('백업 생성 오류: $e');
      _showErrorSnackBar('백업 생성 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _backupNameController.clear();
      });
    }
  }
  
  // 백업 복원
  Future<void> _restoreBackup(String id, String name) async {
    if (!_isAuthenticated) {
      _showErrorSnackBar('먼저 로그인해주세요.');
      return;
    }
    
    // 확인 다이얼로그
    final confirm = await _showConfirmDialog(
      '백업 복원',
      '[$name] 백업을 복원하시겠습니까?\n\n현재 데이터는 모두 대체됩니다.',
    );
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _backupService.restoreBackup(id);
      
      if (success) {
        // 데이터베이스 상태 검증
        await _backupService.validateDatabase();
        
        _showSuccessSnackBar('백업이 성공적으로 복원되었습니다.');
        
        // 앱 재시작 안내 다이얼로그
        await _showRestartDialog();
      } else {
        _showErrorSnackBar('백업 복원에 실패했습니다.');
      }
    } catch (e) {
      print('백업 복원 오류: $e');
      _showErrorSnackBar('백업 복원 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 백업 삭제
  Future<void> _deleteBackup(String id, String name) async {
    if (!_isAuthenticated) {
      _showErrorSnackBar('먼저 로그인해주세요.');
      return;
    }
    
    // 확인 다이얼로그
    final confirm = await _showConfirmDialog(
      '백업 삭제',
      '[$name] 백업을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
    );
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _backupService.deleteBackup(id);
      
      if (success) {
        // 백업 리스트 다시 로드
        await _loadBackups();
        
        _showSuccessSnackBar('백업이 성공적으로 삭제되었습니다.');
      } else {
        _showErrorSnackBar('백업 삭제에 실패했습니다.');
      }
    } catch (e) {
      print('백업 삭제 오류: $e');
      _showErrorSnackBar('백업 삭제 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 백업 이름 다이얼로그
  Future<void> _showBackupNameDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('백업 이름 설정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('백업 파일의 이름을 설정해주세요. (선택사항)'),
                SizedBox(height: 16),
                TextField(
                  controller: _backupNameController,
                  decoration: InputDecoration(
                    hintText: '예: 토익단어_완료',
                    border: OutlineInputBorder(),
                    labelText: '백업 이름',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                _backupNameController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // 확인 다이얼로그
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  // 앱 재시작 안내 다이얼로그
  Future<void> _showRestartDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('복원 완료'),
          content: Text('백업이 성공적으로 복원되었습니다.\n\n변경사항을 적용하기 위해 앱을 다시 시작해주세요.'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // 에러 스낵바
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // 성공 스낵바
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // 사용자 정보 카드
  Widget _buildUserInfoCard(bool isDarkMode) {
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300, 
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Drive 백업',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (_isAuthenticated) ...[
              // 사용자 정보 표시
              Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 24,
                    color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_userName != null && _userName!.isNotEmpty)
                          Text(
                            _userName!,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (_userEmail != null)
                          Text(_userEmail!),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleSignOut,
                    child: Text('로그아웃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 로그인 버튼
              Row(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 24,
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google Drive에 단어장 데이터를 백업하고 다른 기기와 동기화할 수 있습니다.',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleSignIn,
                  icon: Icon(Icons.login),
                  label: Text('Google 계정으로 로그인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // 백업 상태 카드
  Widget _buildBackupStatusCard(bool isDarkMode) {
    final hasBackup = _lastBackupTime != null;
    
    // 마지막 백업 시간 포맷
    String lastBackupText = '백업 없음';
    if (hasBackup) {
      final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
      lastBackupText = dateFormat.format(_lastBackupTime!);
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode 
              ? Colors.amber.shade800.withOpacity(0.5)
              : Colors.amber.shade300,
          width: 1,
        ),
      ),
      color: isDarkMode 
          ? Colors.amber.shade900.withOpacity(0.2) 
          : Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.backup,
                  color: isDarkMode 
                      ? Colors.amber.shade300 
                      : Colors.amber.shade700,
                ),
                SizedBox(width: 8),
                Text(
                  '백업 상태',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode 
                        ? Colors.amber.shade300 
                        : Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '마지막 백업: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(lastBackupText),
                ),
              ],
            ),
            if (_lastBackupName != null && _lastBackupName!.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '백업 이름: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(_lastBackupName!),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: Icon(Icons.cloud_upload),
                label: Text('새 백업 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode 
                      ? Colors.amber.shade700 
                      : Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 백업 목록
  Widget _buildBackupList(bool isDarkMode) {
    if (_backups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              '백업 파일이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '상단의 새 백업 생성 버튼을 눌러 백업을 시작하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final backup = _backups[index];
        final id = backup['id'] as String;
        final name = backup['name'] as String;
        final date = backup['date'] as DateTime;
        final size = backup['size'] as num;
        
        // 날짜 포맷
        final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
        final dateText = dateFormat.format(date);
        
        // 파일 크기 포맷
        String sizeText;
        if (size < 1024) {
          sizeText = '$size B';
        } else if (size < 1024 * 1024) {
          sizeText = '${(size / 1024).toStringAsFixed(1)} KB';
        } else {
          sizeText = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
        
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _restoreBackup(id, name),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.backup,
                        size: 20,
                        color: isDarkMode 
                            ? Colors.blue.shade300 
                            : Colors.blue.shade600,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        onPressed: () => _deleteBackup(id, name),
                        tooltip: '백업 삭제',
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        sizeText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('데이터 백업 및 복원'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 로그인 상태 및 사용자 정보 표시
                _buildUserInfoCard(isDarkMode),
                
                // 전체 백업 상태
                if (_isAuthenticated) _buildBackupStatusCard(isDarkMode),
                
                // 백업 목록
                if (_isAuthenticated) Expanded(
                  child: _buildBackupList(isDarkMode),
                ),
              ],
            ),
      floatingActionButton: _isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: _loadBackups,
              label: Text('새로고침'),
              icon: Icon(Icons.refresh),
              backgroundColor: isDarkMode 
                  ? Colors.blue.shade700 
                  : Colors.blue.shade600,
            )
          : null,
    );
  }
}