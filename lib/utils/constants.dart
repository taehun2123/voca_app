// lib/utils/constants.dart

import 'dart:convert';

class AppConstants {
  // 인앱 결제 상품 ID
  static const String credits10ProductId = 'com.taehun2123.capturevoca.credits.10';
  static const String credits30ProductId = 'com.taehun2123.capturevoca.credits.30';
  static const String credits60ProductId = 'com.taehun2123.capturevoca.credits.60';

  // 초기 무료 사용량
  static const int initialFreeCredits = 10;
  
  // API 키 보호를 위한 XOR 시크릿 키
  static final List<int> apiKeySecret = utf8.encode('vocabularyAppSecretKey2025');
  
  // 앱 버전
  static const String appVersion = '1.0.0';
  
  // OpenAI 모델 설정
  static const String openAiModel = 'gpt-4.1-mini'; 
  static const int maxTokens = 4000;
}