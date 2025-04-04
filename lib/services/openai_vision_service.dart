// lib/services/openai_vision_service.dart (수정)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/word_entry.dart';
import '../utils/api_key_utils.dart';
import '../utils/constants.dart';
import '../services/purchase_service.dart';

class OpenAIVisionService {
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  final PurchaseService _purchaseService = PurchaseService();

  // 이미지 파일에서 단어 추출 (사용량 체크 추가)
  Future<List<WordEntry>> extractWordsFromImage(File imageFile) async {
    // 이 함수는 이제 사용량 체크를 하지 않음 - 상위 프로세스에서 처리
    try {
      // API 키 가져오기 (보호된 방식)
      final apiKey = ApiKeyUtils.getApiKey();
      print(
          'OpenAIVisionService: API 키 상태: ${apiKey.isEmpty ? "비어 있음" : "설정됨"}');
      if (apiKey.isEmpty) {
        throw Exception('API 키를 사용할 수 없습니다.');
      }

      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // OpenAI API 요청 본문 준비 - 프롬프트 개선
      final payload = jsonEncode({
        "model": AppConstants.openAiModel, // 환경설정에서 정의된 모델
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": """
                이 이미지는 영어 단어와 한국어 뜻이 나열된 영어 단어장입니다. 
                이미지에서 영어 단어와 그 의미를 추출해주세요.
                
                다음 정보를 각 단어별로 추출해주세요:
                1. 영어 단어 (word)
                2. 발음 기호가 있다면 발음 기호 (pronunciation) - 없으면 빈 문자열
                3. 한국어 뜻 (meaning)
                4. 영어 예문이 있다면 예문 (examples) - 없으면 빈 배열
                5. 기출 표현이나 관련 구문이 있다면 (commonPhrases) - 없으면 빈 배열
                
                응답은 다음 JSON 형식으로 반환해주세요:
                [
                  {
                    "word": "substantially",
                    "pronunciation": "",
                    "meaning": "실질적으로, 상당히",
                    "examples": [],
                    "commonPhrases": []
                  },
                  {
                    "word": "significantly",
                    "pronunciation": "",
                    "meaning": "상당히, 의미 있게",
                    "examples": [],
                    "commonPhrases": []
                  },
                  ...
                ]
                
                중요: 이미지에 보이는 모든 영어 단어와 한국어 뜻 쌍을 추출해주세요.
                영어 단어가 없거나 한국어 뜻이 없는 경우는 생략합니다.
                발음 기호가 있으면 정확하게 추출해주세요.
                발음 기호가 없는 경우 pronunciation은 빈 문자열로 설정합니다.
                """
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ],
        "max_tokens": AppConstants.maxTokens
      });

      // API 요청 보내기
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: payload,
      );

      // 응답 처리 - 명시적으로 UTF-8 디코딩
      if (response.statusCode == 200) {
        // UTF-8 인코딩 처리를 명시적으로 적용
        final String decodedResponse = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedResponse);
        final content = responseData['choices'][0]['message']['content'];

        // JSON 부분 추출
        final jsonStr = _extractJsonFromString(content);

        try {
          // JSON 파싱하여 WordEntry 객체 리스트로 변환
          final List<dynamic> wordsJson = jsonDecode(jsonStr);
          final List<WordEntry> words =
              wordsJson.map((json) => _parseWordJson(json)).toList();

          print('추출된 단어 수: ${words.length}');
          return words;
        } catch (parseError) {
          print('JSON 파싱 오류: $parseError');
          print('원본 응답: $content');
          throw Exception('응답 데이터를 처리할 수 없습니다. 다시 시도해주세요.');
        }
      } else {
        // 오류 응답도 UTF-8로 디코딩
        final String errorResponse = utf8.decode(response.bodyBytes);
        print('OpenAI API 오류: ${response.statusCode} - $errorResponse');
        throw Exception('API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('단어 추출 중 오류 발생: $e');
      rethrow; // 원래 오류 다시 던지기
    }
  }

  // 문자열에서 JSON 부분만 추출 (기존 메서드)
  String _extractJsonFromString(String text) {
    // JSON 배열 시작과 끝 찾기 (더 견고한 방식)
    final startIndex = text.indexOf('[');
    if (startIndex == -1) return '[]'; // JSON 배열 시작을 찾지 못한 경우

    // 중괄호 계수를 사용하여 JSON 텍스트 경계 찾기
    int bracketCount = 0;
    int endIndex = text.length - 1;

    for (int i = startIndex; i < text.length; i++) {
      final char = text[i];
      if (char == '[') bracketCount++;
      if (char == ']') {
        bracketCount--;
        if (bracketCount == 0) {
          endIndex = i + 1;
          break;
        }
      }
    }

    // JSON 부분만 추출
    try {
      final jsonPart = text.substring(startIndex, endIndex);
      // 유효성 테스트 (파싱 가능한지 확인)
      jsonDecode(jsonPart);
      return jsonPart;
    } catch (e) {
      print('JSON 추출 오류: $e');

      // JSON 형식 복구 시도
      try {
        // 괄호 균형이 맞지 않는 경우 처리
        var attemptFix = text.substring(startIndex);
        if (!attemptFix.endsWith(']')) {
          attemptFix += ']';
        }

        // 테스트
        jsonDecode(attemptFix);
        return attemptFix;
      } catch (fixError) {
        // 복구 불가능한 경우
        print('JSON 복구 실패: $fixError');
        return '[]';
      }
    }
  }

  // JSON을 WordEntry 객체로 변환 (기존 메서드)
  WordEntry _parseWordJson(Map<String, dynamic> json) {
    // 필드가 없을 경우 기본값 제공
    final word = json['word'] ?? '';
    final pronunciation = json['pronunciation'] ?? '';
    final meaning = json['meaning'] ?? '';

    // 예문과 관용구는 배열로 처리
    List<String> examples = [];
    if (json['examples'] != null) {
      if (json['examples'] is List) {
        examples = List<String>.from(json['examples']);
      } else if (json['examples'] is String) {
        // 문자열인 경우 콤마로 분리
        examples = [json['examples'] as String];
      }
    }

    List<String> commonPhrases = [];
    if (json['commonPhrases'] != null) {
      if (json['commonPhrases'] is List) {
        commonPhrases = List<String>.from(json['commonPhrases']);
      } else if (json['commonPhrases'] is String) {
        commonPhrases = [json['commonPhrases'] as String];
      }
    }

    return WordEntry(
      word: word,
      pronunciation: pronunciation,
      meaning: meaning,
      examples: examples,
      commonPhrases: commonPhrases,
    );
  }
}
