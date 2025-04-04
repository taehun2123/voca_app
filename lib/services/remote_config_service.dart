import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  
  // 기본값 (Remote Config가 초기화되기 전에 사용)
  static const String _defaultApiKey = 'openai_api_key';
  static const String _defaultAdminPasswordHash = 'admin_password'; 
  
  // 설정 키
  static const String _apiKeyParameter = 'openai_api_key';
  static const String _adminPasswordParameter = 'admin_password';
  
  Future<void> initialize() async {
    try {
      // 최소 페치 간격 설정
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      
      // 기본값 설정
      await _remoteConfig.setDefaults({
        _apiKeyParameter: _defaultApiKey,
        _adminPasswordParameter: _defaultAdminPasswordHash,
      });
      
      // 값 페치 및 활성화
      await _remoteConfig.fetchAndActivate();
      
      print('Remote Config 초기화 완료');
    } catch (e) {
      print('Remote Config 초기화 오류: $e');
    }
  }
  
  // API 키 가져오기
  String getApiKey() {
    try {
      final encryptedKey = _remoteConfig.getString(_apiKeyParameter);
      if (encryptedKey.isEmpty) return _defaultApiKey;
      
      // 필요한 경우 여기에 복호화 로직 추가
      return encryptedKey;
    } catch (e) {
      print('API 키 조회 오류: $e');
      return _defaultApiKey;
    }
  }
  
  // 관리자 비밀번호 확인
  bool verifyAdminPassword(String inputPassword) {
    try {
      final storedHash = _remoteConfig.getString(_adminPasswordParameter);
      if (storedHash.isEmpty) return false;
            
      return inputPassword == storedHash;
    } catch (e) {
      print('비밀번호 확인 오류: $e');
      return false;
    }
  }
  
  // 최신 값 새로 가져오기
  Future<bool> refreshConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      return true;
    } catch (e) {
      print('Remote Config 새로고침 오류: $e');
      return false;
    }
  }
}