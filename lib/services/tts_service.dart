import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);  // 느린 속도로 설정 (0.0-1.0)
    await _flutterTts.setVolume(1.0);      // 최대 볼륨 (0.0-1.0)
    await _flutterTts.setPitch(1.0);       // 기본 피치 (0.5-2.0)
    
    _isInitialized = true;
  }

  // 텍스트 발음하기
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await _initTts();
    }
    
    // 기존 발음 중지
    await stop();
    
    // 새 텍스트 발음
    await _flutterTts.speak(text);
  }

  // 발음 중지
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // 리소스 해제
  void dispose() {
    _flutterTts.stop();
  }
  
  // 발음 속도 설정 (0.0-1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }
  
  // 볼륨 설정 (0.0-1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }
  
  // 피치 설정 (0.5-2.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  // 사용 가능한 음성 목록 가져오기
  Future<List<String>> getAvailableVoices() async {
    final voices = await _flutterTts.getVoices;
    if (voices == null) return [];
    
    List<String> voiceNames = [];
    for (var voice in voices) {
      if (voice is Map) {
        final name = voice['name'];
        if (name != null && name.toString().contains('en-')) {
          voiceNames.add(name.toString());
        }
      }
    }
    
    return voiceNames;
  }
  
  // 특정 음성 선택하기
  Future<void> setVoice(String voiceName) async {
    await _flutterTts.setVoice({"name": voiceName, "locale": "en-US"});
  }
}