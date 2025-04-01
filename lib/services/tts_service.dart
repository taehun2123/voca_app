import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AccentType {
  american,   // 미국식
  british,    // 영국식
  australian, // 호주식
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  AccentType _currentAccent = AccentType.american;
  
  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    if (_isInitialized) return;
    
    try {
      // 기본 설정
      if (Platform.isIOS) {
        // iOS 전용 설정
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth]
        );
      } else if (Platform.isAndroid) {
        // Android 전용 설정
        await _flutterTts.setQueueMode(1); // 대기열 추가 모드
      }
      
      // 공통 설정
      await _flutterTts.setLanguage("en-US"); // 기본값: 미국식
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      
      // TTS 이벤트 리스너
      _flutterTts.setStartHandler(() {
        print("TTS 시작");
      });
      
      _flutterTts.setCompletionHandler(() {
        print("TTS 완료");
      });
      
      _flutterTts.setErrorHandler((message) {
        print("TTS 오류: $message");
      });
      
      _isInitialized = true;
    } catch (e) {
      print('TTS 초기화 중 오류: $e');
    }
  }

  // 텍스트 발음하기 (액센트 선택 가능)
  Future<void> speak(String text, {AccentType? accent}) async {
    if (!_isInitialized) {
      await _initTts();
    }
    
    try {
      // 액센트 변경 처리
      if (accent != null && accent != _currentAccent) {
        await _changeAccent(accent);
      }
      
      // 기존 발음 중지
      await stop();
      
      // 새 텍스트 발음
      var result = await _flutterTts.speak(text);
      print("TTS 발음 결과: $result");
    } catch (e) {
      print('발음 중 오류: $e');
    }
  }
  
  // 특정 액센트로 변경
  Future<void> _changeAccent(AccentType accent) async {
    try {
      String language;
      switch (accent) {
        case AccentType.american:
          language = "en-US";
          break;
        case AccentType.british:
          language = "en-GB";
          break;
        case AccentType.australian:
          language = "en-AU";
          break;
      }
      
      await _flutterTts.setLanguage(language);
      _currentAccent = accent;
    } catch (e) {
      print('액센트 변경 중 오류: $e');
    }
  }
  
  // 액센트 직접 설정
  Future<void> setAccent(AccentType accent) async {
    if (!_isInitialized) {
      await _initTts();
    }
    
    await _changeAccent(accent);
  }

  // 발음 중지
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS 중지 중 오류: $e');
    }
  }

  // 리소스 해제
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (e) {
      print('TTS 종료 중 오류: $e');
    }
  }
  
  // 사용 가능한 언어 목록 확인 (디버깅용)
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      print('언어 목록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 사용 가능한 음성 목록 확인
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      if (Platform.isIOS) {
        final voices = await _flutterTts.getVoices;
        List<Map<String, String>> result = [];
        
        for (var voice in voices) {
          try {
            final name = voice['name'] as String?;
            final locale = voice['locale'] as String?;
            
            if (name != null && locale != null) {
              result.add({
                'name': name,
                'locale': locale,
              });
            }
          } catch (e) {
            print('음성 정보 처리 오류: $e');
          }
        }
        
        return result;
      } else {
        // Android는 다른 방식으로 처리
        return [];
      }
    } catch (e) {
      print('음성 목록 가져오기 오류: $e');
      return [];
    }
  }
}