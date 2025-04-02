import 'package:flutter/material.dart';
import '../services/api_key_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
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
                          Text(
                            'OpenAI API 설정',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                            '• 무슨 일이 있어도 해당 API 키는 개발자에게 전송되지 않습니다! 안심하고 사용하세요.\n\n',
                            style: TextStyle(color: Colors.grey[700]),
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