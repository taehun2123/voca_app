import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/remote_config_service.dart';

class ApiKeyUtils {
  static String getApiKey() {
    try {
      // Remote Config에서만 API 키 가져오기
      final remoteConfigService = RemoteConfigService();
      final apiKey = remoteConfigService.getApiKey();
      
      if (apiKey.isEmpty) {
        print('Remote Config에 API 키가 없습니다');
      }
      
      return apiKey;
    } catch (e) {
      print('API 키 가져오기 오류: $e');
      return '';
    }
  }
}
