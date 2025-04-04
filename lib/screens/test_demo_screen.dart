import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocabulary_app/screens/home_screen.dart';
import 'package:vocabulary_app/utils/api_key_utils.dart';
import '../model/word_entry.dart';
import '../services/openai_vision_service.dart';
import '../services/api_key_service.dart';
import 'package:vocabulary_app/services/purchase_service.dart';


class TestDemoScreen extends StatefulWidget {
  final File imageFile;
  
  const TestDemoScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  _TestDemoScreenState createState() => _TestDemoScreenState();
}

class _TestDemoScreenState extends State<TestDemoScreen> {
  final ApiKeyService _apiKeyService = ApiKeyService();
  final PurchaseService _purchaseService = PurchaseService(); // 추가
  OpenAIVisionService? _visionService;
  List<WordEntry>? _extractedWords;
  bool _isLoading = true;
  bool _hasUsage = true; // 사용량 체크 변수 추가
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
      
      final usages = await _purchaseService.getRemainingUsages();
        setState(() {
          _hasUsage = usages > 0;
        });
            
      // 테스트 기능은 자체 API 키 사용
      final apiKey = ApiKeyUtils.getApiKey();
      if (apiKey.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '오류: API 키를 사용할 수 없습니다.';
        });
        return;
      }
      
      // Vision 서비스 초기화
      _visionService = OpenAIVisionService();

      // 사용량 부족 시에는 메시지 표시만 하고 처리는 하지 않음
      if (!_hasUsage) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

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
          if (_visionService != null && _hasUsage)
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
          // 사용량 부족 시 안내
          if (!_hasUsage)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off,
                      color: Colors.orange,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '사용 가능한 횟수가 부족합니다',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '단어 인식 테스트를 사용하려면 사용권을 구매해주세요.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // 구매 화면으로 이동하는 코드 추가 (홈 화면을 통해)
                      },
                      child: Text('사용권 구매하기'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoading)
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
                : !_hasUsage
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
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (word.pronunciation.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                              child: Text(
                                                word.pronunciation,
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',  // 발음 기호에 적합한 폰트
                                                  fontSize: 14.0,
                                                  fontStyle: FontStyle.italic,
                                                  letterSpacing: 0.2,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          Text(
                                            word.meaning,
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (word.examples.isNotEmpty) ...[
                                                Text(
                                                  '예문:',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 4),
                                                ...word.examples.map((example) => Padding(
                                                      padding: EdgeInsets.only(bottom: 4),
                                                      child: Text(
                                                        '• $example',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          height: 1.4,
                                                        ),
                                                      ),
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
                                                      child: Text(
                                                        '• $phrase',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          height: 1.4,
                                                        ),
                                                      ),
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
      floatingActionButton:  _hasUsage && !_isLoading && (_extractedWords != null && _extractedWords!.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, const HomePage());
              },
              icon: Icon(Icons.home),
              label: Text('홈으로 가기'),
            )
          : null,
    );
  }
}