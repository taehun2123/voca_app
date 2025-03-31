import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService {
  static const String _apiKeyBoxName = 'apiKeyBox';
  static const String _openaiApiKeyKey = 'openai_api_key';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Box? _apiKeyBox;
  
  // 초기화
  Future<void> init() async {
    if (_apiKeyBox == null || !_apiKeyBox!.isOpen) {
      _apiKeyBox = await Hive.openBox(_apiKeyBoxName);
    }
  }
  
  // OpenAI API 키 저장
  Future<void> saveOpenAIApiKey(String apiKey) async {
    await init();
    await _secureStorage.write(key: _openaiApiKeyKey, value: apiKey);
  }
  
  // OpenAI API 키 가져오기
  Future<String?> getOpenAIApiKey() async {
    return await _secureStorage.read(key: _openaiApiKeyKey);
  }
  
  // API 키가 설정되었는지 확인
  Future<bool> hasOpenAIApiKey() async {
    final apiKey = await getOpenAIApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  // API 키 삭제
  Future<void> deleteOpenAIApiKey() async {
    await _secureStorage.delete(key: _openaiApiKeyKey);
  }
}