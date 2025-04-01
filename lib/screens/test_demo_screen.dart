import 'dart:io';
import 'package:flutter/material.dart';
import '../model/word_entry.dart';
import '../services/openai_vision_service.dart';
import '../services/api_key_service.dart';

class TestDemoScreen extends StatefulWidget {
  final File imageFile;
  
  const TestDemoScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  _TestDemoScreenState createState() => _TestDemoScreenState();
}

class _TestDemoScreenState extends State<TestDemoScreen> {
  final ApiKeyService _apiKeyService = ApiKeyService();
  OpenAIVisionService? _visionService;
  List<WordEntry>? _extractedWords;
  bool _isLoading = true;
  bool _hasApiKey = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _initializeAndProcess();
  }
  
  Future<void> _initializeAndProcess() async {
    try {
      // API 키 확인
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final apiKey = await _apiKeyService.getOpenAIApiKey();
      
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasApiKey = false;
          _errorMessage = 'OpenAI API 키가 설정되지 않았습니다.';
        });
        return;
      }
      
      // Vision 서비스 초기화
      _visionService = OpenAIVisionService(apiKey: apiKey);
      setState(() {
        _hasApiKey = true;
      });
      
      // 이미지 처리
      await _processImage();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '초기화 중 오류: $e';
      });
    }
  }
  
  Future<void> _processImage() async {
    if (_visionService == null) {
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final words = await _visionService!.extractWordsFromImage(widget.imageFile);
      
      setState(() {
        _extractedWords = words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '이미지 처리 중 오류: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('단어 인식 테스트'),
        actions: [
          if (_visionService != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _processImage,
              tooltip: '다시 처리',
            ),
        ],
      ),
      body: Column(
        children: [
          // 이미지 표시
          Container(
            height: 200,
            width: double.infinity,
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.contain,
            ),
          ),
          
          Divider(),
          
          // 추출 결과
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('OpenAI Vision API로 이미지 분석 중...'),
                      ],
                    ),
                  )
                : !_hasApiKey
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'API 키가 설정되지 않았습니다',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '설정 화면에서 OpenAI API 키를 입력해주세요',
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('돌아가기'),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  '오류가 발생했습니다',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _processImage,
                                  child: Text('다시 시도'),
                                ),
                              ],
                            ),
                          )
                        : _extractedWords == null || _extractedWords!.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, color: Colors.grey, size: 48),
                                    SizedBox(height: 16),
                                    Text(
                                      '단어를 추출하지 못했습니다',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '다른 이미지를 사용하거나 더 선명한 사진으로 시도해보세요',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _extractedWords!.length,
                                itemBuilder: (context, index) {
                                  final word = _extractedWords![index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    child: ExpansionTile(
                                      title: Text(
                                        word.word,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Text(word.meaning),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (word.pronunciation.isNotEmpty) ...[
                                                Text(
                                                  '발음: ${word.pronunciation}',
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                              ],
                                              if (word.examples.isNotEmpty) ...[
                                                Text(
                                                  '예문:',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 4),
                                                ...word.examples.map((example) => Padding(
                                                      padding: EdgeInsets.only(bottom: 4),
                                                      child: Text('• $example'),
                                                    )),
                                                SizedBox(height: 8),
                                              ],
                                              if (word.commonPhrases.isNotEmpty) ...[
                                                Text(
                                                  '관용구:',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 4),
                                                ...word.commonPhrases.map((phrase) => Padding(
                                                      padding: EdgeInsets.only(bottom: 4),
                                                      child: Text('• $phrase'),
                                                    )),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
      floatingActionButton: _hasApiKey && !_isLoading && (_extractedWords != null && _extractedWords!.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: 추출된 단어를 단어장에 저장하는 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('향후 업데이트에서 단어 저장 기능이 추가될 예정입니다.')),
                );
              },
              icon: Icon(Icons.save),
              label: Text('단어장에 추가'),
            )
          : null,
    );
  }
}