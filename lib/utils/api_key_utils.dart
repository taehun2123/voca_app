// lib/utils/api_key_utils.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vocabulary_app/utils/constants.dart';

/// OpenAI API 키 관리 유틸리티
class ApiKeyUtils {
  static const String _encodedApiKey = 'BQROERAaBkwDLHEYAwIuKUo6BTtUSWIBQ31DVysLJjchAhA1CgQlHSMGLQ0efSsddwVZGDI9IS0FGg0kMBYCHDc+KRoCVQUgJ0xGRgZyQxg6NjZGLg0QEgc6KjcNMygqLQYDD2tGWlclGhkzMgUHJj8vHiopOgoJKiAhclwYAlFAQTo6GwczIg4lMAwAGDNrKVoDB0UqEkkLaUMNDjkyURAyVCA=';
  
  /// 디코딩된 API 키 반환
  static String getApiKey() {
    try {
      final decodedBytes = base64Decode(_encodedApiKey);
      final result = _xorDecode(decodedBytes, AppConstants.apiKeySecret);
      return utf8.decode(result);
    } catch (e) {
      debugPrint('API 키 디코딩 오류: $e');
      return '';
    }
  }
  
  /// 디버그 모드에서만 작동하는 API 키 인코더 (개발용)
  // static String encodeApiKey(String originalKey) {
  //   assert(kDebugMode, 'API 키 인코딩은 디버그 모드에서만 사용 가능합니다');
  //   if (!kDebugMode) return '';
    
  //   final bytes = utf8.encode(originalKey);
  //   final encoded = _xorEncode(bytes, AppConstants.apiKeySecret);
  //   return base64Encode(encoded);
  // }
  
  // XOR 인코딩
  static List<int> _xorEncode(List<int> input, List<int> key) {
    List<int> output = [];
    for (int i = 0; i < input.length; i++) {
      output.add(input[i] ^ key[i % key.length]);
    }
    return output;
  }
  
  // XOR 디코딩
  static List<int> _xorDecode(List<int> input, List<int> key) {
    return _xorEncode(input, key); // XOR은 인코딩/디코딩이 동일함
  }
}