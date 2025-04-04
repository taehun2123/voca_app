import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/remote_config_service.dart';

class ApiKeyUtils {
  static String getApiKey() {
    try {
      // Remote Config에서 API 키 가져오기
      final remoteConfigService = RemoteConfigService();
      return remoteConfigService.getApiKey();
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return '';
    }
  }
}