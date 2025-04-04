// lib/utils/constants.dart

import 'dart:convert';

class AppConstants {
  // 인앱 결제 상품 ID
  static const String credits10ProductId = 'com.taehun2123.capturevoca.credits.10';
  static const String credits30ProductId = 'com.taehun2123.capturevoca.credits.30';
  static const String credits100ProductId = 'com.taehun2123.capturevoca.credits.100';

  // 초기 무료 사용량xz
  static const int initialFreeCredits = 7;
  
  // API 키 보호를 위한 XOR 시크릿 키
  static final List<int> apiKeySecret = utf8.encode('vocabularyAppSecretKey2025');
  
  // 앱 버전
  static const String appVersion = '1.0.0';
  
  // OpenAI 모델 설정
  static const String openAiModel = 'gpt-4o-mini'; // 또는 gpt-4o
  static const int maxTokens = 4000;
}