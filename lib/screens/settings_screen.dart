import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_key_service.dart';
import '../widgets/api_guide_screen.dart'; // 상세 가이드 화면 import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiKeyService _apiKeyService = ApiKeyService();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _hasApiKey = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = await _apiKeyService.getOpenAIApiKey();
    final hasKey = await _apiKeyService.hasOpenAIApiKey();

    setState(() {
      if (apiKey != null) {
        _apiKeyController.text = apiKey;
      }
      _hasApiKey = hasKey;
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 키를 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _apiKeyService.saveOpenAIApiKey(_apiKeyController.text.trim());

    setState(() {
      _hasApiKey = true;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API 키가 저장되었습니다')),
    );
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API 키 삭제'),
        content: Text('저장된 API 키를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      await _apiKeyService.deleteOpenAIApiKey();
      _apiKeyController.clear();

      setState(() {
        _hasApiKey = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 키가 삭제되었습니다')),
      );
    }
  }

  // API 도움말 다이얼로그 표시
  void _showApiHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('API 키란?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OpenAI API 키는 이 앱이 OpenAI의 인공지능 서비스를 사용하기 위한 인증 수단입니다.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 16),
              Text(
                '주요 사항:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('API 키는 OpenAI 계정에서 발급받을 수 있습니다.'),
              _buildBulletPoint('API 키는 비밀번호처럼 안전하게 보관해야 합니다.'),
              _buildBulletPoint('이 앱에서는 이미지 단어 인식을 위해 API 키를 사용합니다.'),
              _buildBulletPoint('API 사용 시 OpenAI 측에 요금이 발생할 수 있습니다.'),
              SizedBox(height: 16),
              Text(
                '보안 정보:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('API 키는 앱 내부에만 안전하게 저장되며 외부로 전송되지 않습니다.'),
              _buildBulletPoint('API 키를 통한 모든 통신은 암호화된 HTTPS로 이루어집니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 상세 가이드 화면으로 이동하는 옵션 추가
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApiGuideScreen()),
              );
            },
            child: Text('상세 가이드 보기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // API 발급 및 결제 방법 다이얼로그 표시 (간략 버전)
  void _showApiRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payments_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('API 발급 및 결제 방법'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OpenAI API 키 발급 및 결제 설정 방법입니다:',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 16),
              Text(
                '1. API 키 발급하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildNumberedStep('OpenAI 웹사이트(https://openai.com)에 접속합니다.'),
              _buildNumberedStep('회원가입 또는 로그인합니다. (Open AI Platform 선택 로그인 권장)'),
              _buildNumberedStep('좌측 메뉴의 "API Platform"을 선택합니다.'),
              _buildNumberedStep('우측 상단 톱니바퀴 아이콘 선택 후 좌측메뉴에서 API Keys를 선택합니다.'),
              _buildNumberedStep('"Create new secret key"를 클릭하여 API 키를 생성합니다.'),
              _buildNumberedStep('생성된 API 키를 안전한 곳에 저장합니다.'),
              SizedBox(height: 16),
              Text(
                '2. 결제 수단 설정하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildNumberedStep('OpenAI - Open API Platform - 우측상단 톱니바퀴 아이콘 - 좌측 메뉴의 Billing 섹션으로 이동합니다.'),
              _buildNumberedStep('Add to credit balance을 선택합니다.'),
              _buildNumberedStep('원하는 달러 크레딧(달러 단위 결제)을 입력 후, 신용카드 정보를 입력하고 결제 수단을 등록합니다.'),
              _buildNumberedStep('크레딧 소진 후에는 사용량에 따라 요금이 부과됩니다. \n자동 부과를 원하시지 않으시면 auto recharg부분을 disable하세요.'),
              SizedBox(height: 16),
              Text(
                '3. 요금 안내',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildNumberedStep('GPT-4o-mini 모델 기준으로 이미지 1장당 약 0.01~0.02 달러가 부과됩니다.'),
              _buildNumberedStep('결제는 OpenAI를 통해 직접 이루어지며, 이 앱은 결제 정보에 접근하지 않습니다.'),
              _buildNumberedStep('자세한 요금 정보는 OpenAI 웹사이트에서 확인하세요.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '발급받은 API 키를 복사하여 이 앱의 설정 화면에 붙여넣으면 단어장 이미지 인식 기능을 사용할 수 있습니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 상세 가이드 화면으로 이동
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApiGuideScreen()),
              );
            },
            child: Text('이미지로 보기'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'https://platform.openai.com/'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('OpenAI 사이트 주소가 클립보드에 복사되었습니다')),
              );
            },
            child: Text('사이트 주소 복사'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 불릿 포인트 위젯
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // 번호 매기기 위젯
  Widget _buildNumberedStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('- ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        actions: [
          // 상단 앱바에 상세 가이드 버튼 추가
          IconButton(
            icon: Icon(Icons.menu_book_outlined),
            tooltip: '상세 설정 가이드',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApiGuideScreen()),
              );
            },
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
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'OpenAI API 설정',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  // API 도움말 아이콘
                                  IconButton(
                                    icon: Icon(Icons.help_outline, 
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    tooltip: 'API 키란?',
                                    onPressed: _showApiHelpDialog,
                                  ),
                                  // API 발급 및 결제 방법 아이콘
                                  IconButton(
                                    icon: Icon(Icons.payments_outlined, 
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    tooltip: 'API 발급 및 결제 방법',
                                    onPressed: _showApiRegistrationDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '단어장 이미지 인식을 위해 OpenAI API 키가 필요합니다. '
                            'API 키는 OpenAI 웹사이트에서 발급받을 수 있습니다.',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _apiKeyController,
                            decoration: InputDecoration(
                              labelText: 'OpenAI API 키',
                              hintText: 'sk-...',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                              ),
                            ),
                            obscureText: _isObscured,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: _saveApiKey,
                                child: Text('저장'),
                              ),
                              if (_hasApiKey)
                                OutlinedButton(
                                  onPressed: _deleteApiKey,
                                  child: Text('삭제'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이미지 인식 정보',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '이 앱은 OpenAI의 GPT-4o-mini Model을 사용하여 단어장 이미지에서 단어, 발음, 의미, 예문 등을 자동으로 추출합니다.\n\n'
                            '아래의 정보는 API 등록에 관한 정보입니다. 잘 읽어주시길 바랍니다.\n',
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• API 등록 뿐만 아니라, OPEN API 홈페이지에서 결제수단 및 선결제를 하셔야 이용이 가능합니다.\n\n'
                            '• 이미지는 분석을 위해 OpenAI 서버로 전송되며, 처리 후 삭제됩니다.\n\n'
                            '• 더 나은 인식 결과를 위해 밝고 선명한 이미지를 사용하세요.\n\n'
                            '• 사용료는 달러로 0.01 ~ 0.02 까지 발생합니다 참고 바랍니다.\n\n'
                            '• 무슨 일이 있어도 해당 API 키는 개발자에게 전송되지 않습니다! 안심하고 사용하세요.\n\n'
                            '• 개발자 연락처: devhundeveloper@gmail.com 버그 수정/제안 등 건의 부탁드립니다!',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(height: 16),
                          // 상세 가이드 링크 추가
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ApiGuideScreen()),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.menu_book, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    '이미지로 보는 API 설정 가이드',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}