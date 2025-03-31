import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/word_entry.dart';

class OpenAIVisionService {
  final String _apiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIVisionService({required String apiKey}) : _apiKey = apiKey;

  // 이미지 파일에서 단어 추출
  Future<List<WordEntry>> extractWordsFromImage(File imageFile) async {
    try {
      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // OpenAI API 요청 본문 준비
      final payload = jsonEncode({
        "model": "gpt-4-vision-preview",
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": """
                Extract English vocabulary words from this image of a textbook or vocabulary list.
                For each word, identify:
                1. The word itself
                2. Pronunciation (in square brackets or phonetic symbols)
                3. Meaning in Korean
                4. Example sentences in English
                5. Common phrases or expressions (labeled as 기출 표현 if present)
                
                Return the data in JSON format with this structure:
                [
                  {
                    "word": "example",
                    "pronunciation": "[ɪɡˈzæmpəl]",
                    "meaning": "예시, 보기",
                    "examples": ["This is an example sentence."],
                    "commonPhrases": ["a good example of collaboration"]
                  }
                ]
                
                Include all words visible in the image that have clear English-Korean pairs.
                """
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "max_tokens": 4000
      });

      // API 요청 보내기
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: payload,
      );

      // 응답 처리
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        
        // JSON 부분 추출 (경우에 따라 전체 텍스트 중 JSON만 파싱해야 할 수 있음)
        final jsonStr = _extractJsonFromString(content);
        
        // JSON 파싱하여 WordEntry 객체 리스트로 변환
        final List<dynamic> wordsJson = jsonDecode(jsonStr);
        final List<WordEntry> words = wordsJson.map((json) => _parseWordJson(json)).toList();
        
        return words;
      } else {
        print('OpenAI API 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('단어 추출 중 오류 발생: $e');
      return [];
    }
  }
  
  // 문자열에서 JSON 부분만 추출
  String _extractJsonFromString(String text) {
    // 괄호 계수를 사용하여 JSON 텍스트 경계 찾기
    final startIndex = text.indexOf('[');
    if (startIndex == -1) return '[]'; // JSON 배열 시작을 찾지 못한 경우
    
    int bracketCount = 0;
    int endIndex = startIndex;
    
    for (int i = startIndex; i < text.length; i++) {
      if (text[i] == '[') bracketCount++;
      if (text[i] == ']') bracketCount--;
      
      if (bracketCount == 0) {
        endIndex = i + 1;
        break;
      }
    }
    
    return text.substring(startIndex, endIndex);
  }
  
  // JSON을 WordEntry 객체로 변환
  WordEntry _parseWordJson(Map<String, dynamic> json) {
    return WordEntry(
      word: json['word'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      meaning: json['meaning'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      commonPhrases: List<String>.from(json['commonPhrases'] ?? []),
    );
  }
}