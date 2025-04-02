import 'dart:io';
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
  
  // TTS 가용성 상태
  bool get isAvailable => _isInitialized;
  
  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // iOS와 안드로이드를 위한 플랫폼별 설정
      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ]
        );
      } else if (Platform.isAndroid) {
        await _flutterTts.setQueueMode(1); // 대기열 추가 모드
        // Android 11+ 오디오 포커스 설정
      }
      
      // 공통 설정
      await _flutterTts.setLanguage("en-US"); // 기본값: 미국식
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      
      // 사용 가능한 언어 확인
      final languages = await _flutterTts.getLanguages;
      print("사용 가능한 TTS 언어: $languages");
      
      // 사용 가능한 음성 출력
      if (Platform.isIOS) {
        final voices = await _flutterTts.getVoices;
        print("사용 가능한 TTS 음성: $voices");
      }
      
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
      _isInitialized = false;
    }
  }

  // 텍스트 발음하기 (액센트 선택 가능)
  Future<void> speak(String text, {AccentType? accent}) async {
    if (!_isInitialized) {
      await _initTts();
      
      if (!_isInitialized) {
        print("TTS 서비스를 초기화할 수 없습니다.");
        return;
      }
    }
    
    try {
      // 액센트 변경 처리
      if (accent != null && accent != _currentAccent) {
        await _changeAccent(accent);
      }
      
      // 기존 발음 중지
      await stop();
      
      // 새 텍스트 발음
      await _flutterTts.speak(text);
    } catch (e) {
      print('발음 중 오류: $e');
      // 오류 발생 시 다시 초기화 시도
      _isInitialized = false;
      await _initTts();
    }
  }
  
  // 특정 액센트로 변경
  Future<void> _changeAccent(AccentType accent) async {
    try {
      String language;
      double rate = 0.5; // 기본 속도
      
      // 액센트별 언어 코드 및 속도 조정
      switch (accent) {
        case AccentType.american:
          language = "en-US";
          break;
        case AccentType.british:
          language = "en-GB";
          rate = 0.45; // 영국식은 약간 느리게
          break;
        case AccentType.australian:
          language = "en-AU";
          rate = 0.48; // 호주식도 약간 속도 조정
          break;
      }
      
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(rate);
      _currentAccent = accent;
      print("액센트 변경: $language");
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
  
  // 액센트 이름 가져오기
  String getAccentName(AccentType accent) {
    switch (accent) {
      case AccentType.american:
        return "미국식";
      case AccentType.british:
        return "영국식";
      case AccentType.australian:
        return "호주식";
    }
  }
  
  // 현재 액센트 가져오기
  AccentType getCurrentAccent() {
    return _currentAccent;
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
  
  // 사용 가능한 언어 목록 확인
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