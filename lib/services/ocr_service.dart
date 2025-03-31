import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../model/word_entry.dart';

class OcrService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  OcrService();

  // 리소스 해제
  void dispose() {
    _textRecognizer.close();
  }

  // 이미지 파일로부터 텍스트 인식
  Future<String> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  // 인식된 텍스트에서 단어 정보 파싱
  List<WordEntry> parseRecognizedText(String text) {
    List<WordEntry> result = [];
    
    // 텍스트 라인별로 나누기
    List<String> lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      // 단어 패턴 확인 (녹색 텍스트와 발음 패턴)
      if (line.isNotEmpty && line.contains('[')) {
        try {
          // 단어와 발음 추출
          String word = line.split('[')[0].trim();
          String pronunciation = '[${line.split('[')[1]}';
          
          // 너무 짧은 단어나 발음 무시
          if (word.length < 2 || !pronunciation.endsWith(']')) {
            continue;
          }
          
          // 의미 추출
          String meaning = '';
          List<String> examples = [];
          List<String> phrases = [];
          
          // 다음 줄부터 관련 정보 찾기
          for (int j = i + 1; j < lines.length && j < i + 10; j++) {
            String nextLine = lines[j].trim();
            
            // 다음 단어 패턴이 나오면 중단
            if (nextLine.contains('[') && nextLine.split('[')[0].trim().length > 1) {
              break;
            }
            
            // 의미를 찾음
            if (nextLine.startsWith(word) && nextLine.contains('a.')) {
              meaning = nextLine.split('a.')[1].trim();
            } else if (nextLine.contains('a.') && nextLine.contains(word.toLowerCase())) {
              meaning = nextLine.split('a.')[1].trim();
            }
            // 예문을 찾음 (단어가 포함되어 있고 문장 형태인 경우)
            else if ((nextLine.contains(word) || nextLine.contains(word.toLowerCase())) && 
                    nextLine.contains('.') && 
                    nextLine.length > 15) {
              examples.add(nextLine);
            }
            // 기출 표현 박스 찾기
            else if ((nextLine.contains(word.toLowerCase()) || nextLine.contains(word)) && 
                    (nextLine.contains('beneficial') || 
                    nextLine.contains('supportive') ||
                    nextLine.contains('unexpectedly') ||
                    nextLine.contains('explicitly') ||
                    nextLine.contains('mutually') ||
                    nextLine.contains('happen'))) {
              phrases.add(nextLine);
            }
          }
          
          // 최소한 단어와 발음이 있으면 추가
          if (word.isNotEmpty && pronunciation.isNotEmpty) {
            result.add(WordEntry(
              word: word,
              pronunciation: pronunciation,
              meaning: meaning,
              examples: examples,
              commonPhrases: phrases,
            ));
          }
        } catch (e) {
          // 파싱 중 오류가 발생하면 건너뛰기
          continue;
        }
      }
    }
    
    return result;
  }

  // 이미지 파일에서 단어 추출 (인식 + 파싱 한번에)
  Future<List<WordEntry>> extractWordsFromImage(File imageFile) async {
    final text = await recognizeText(imageFile);
    return parseRecognizedText(text);
  }
}