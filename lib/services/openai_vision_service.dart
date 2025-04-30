// lib/services/openai_vision_service.dart (개선)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/word_entry.dart';
import '../utils/api_key_utils.dart';
import '../utils/constants.dart';

class OpenAIVisionService {
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // 이미지 파일에서 단어 추출
  Future<List<WordEntry>> extractWordsFromImage(File imageFile) async {
    try {
      // API 키 가져오기
      final apiKey = ApiKeyUtils.getApiKey();
      print(
          'OpenAIVisionService: API 키 상태: ${apiKey.isEmpty ? "비어 있음" : "설정됨"}');
      if (apiKey.isEmpty) {
        throw Exception('API 키를 사용할 수 없습니다.');
      }

      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // OpenAI API 요청 본문 준비 - 향상된 프롬프트
      final payload = jsonEncode({
        "model": AppConstants.openAiModel,
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": """
                이 이미지는 영어 단어장입니다. 영어 단어와 한국어 뜻, 그리고 가능한 경우 발음 기호, 예문, 관련 구문이 포함되어 있습니다.
                이미지의 모든 정보를 정확하게 추출해주세요.
                
                각 단어별로 다음 정보를 정확히 추출해 주세요:
                1. 영어 단어 (word) - 필수
                2. 발음 기호 (pronunciation) - 괄호 안에 있는 발음 기호나 [səbˈstænʃəli]와 같은 형태로 표기된 발음 기호를 추출해주세요. 없으면 빈 문자열로 설정.
                3. 한국어 뜻 (meaning) - 필수
                4. 영어 예문 (examples) - 예문이 있을 경우 전체 문장을 추출하고, 각 예문별로 배열 요소로 분리해주세요. 
                   - 예문에 한국어 번역이 같이 있다면 "영어 예문 - 한국어 번역" 형태로 함께 추출해주세요.
                   - 없으면 빈 배열로 설정.
                5. 관련 구문/기출 표현 (commonPhrases) - 단어와 관련된 구문, 숙어, 콜로케이션 등을 추출해주세요.
                   - 각 구문별로 배열 요소로 분리하고, 구문에 한국어 번역이 있다면 "영어 구문 - 한국어 번역" 형태로 함께 추출해주세요.
                   - 없으면 빈 배열로 설정.
                
                응답은 다음 JSON 형식으로 반환해주세요:
                [
                  {
                    "word": "substantially",
                    "pronunciation": "[səbˈstænʃəli]",
                    "meaning": "실질적으로, 상당히",
                    "examples": ["The new policy has substantially changed how we operate. - 새로운 정책은 우리의 운영 방식을 실질적으로 변화시켰다."],
                    "commonPhrases": ["substantially different - 실질적으로 다른", "substantially increase - 상당히 증가하다"]
                  },
                  ...
                ]
                
                중요 지침:
                - 이미지에 있는 모든 영어 단어와 한국어 뜻을 빠짐없이 추출해주세요.
                - 영어 단어와 한국어 뜻은 반드시 포함되어야 합니다. 둘 중 하나라도 없는 경우는 리스트에서 제외해주세요.
                - 발음 기호는 정확하게 추출하고, 기호가 없는 경우 빈 문자열로 설정해주세요.
                - 예문과 관련 구문이 있는 경우 완전한 문장/구문으로 추출하고, 한국어 번역이 있다면 함께 추출해주세요.
                - 단어장에 나타난 모든 정보를 최대한 정확하게 추출해 주세요.
                - 이미지가 기울어져 있거나 품질이 좋지 않더라도 최대한 텍스트를 정확히 인식해주세요.
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

      // 응답 처리
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
      rethrow;
    }
  }

  // 문자열에서 JSON 부분만 추출 (개선된 메서드)
  String _extractJsonFromString(String text) {
    // JSON 배열 시작과 끝 찾기
    final startIndex = text.indexOf('[');
    if (startIndex == -1) return '[]'; // JSON 배열 시작을 찾지 못한 경우

    // 괄호 균형을 맞추어 JSON 끝 찾기
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
      // 유효성 테스트
      jsonDecode(jsonPart);
      return jsonPart;
    } catch (e) {
      print('JSON 추출 오류: $e');

      // JSON 형식 복구 시도
      try {
        // 괄호 균형이 맞지 않는 경우 처리
        var attemptFix = text.substring(startIndex);

        // 열린 괄호와 닫힌 괄호 개수 확인
        int openBrackets = attemptFix.split('[').length - 1;
        int closeBrackets = attemptFix.split(']').length - 1;

        // 닫는 괄호가 부족한 경우 추가
        while (openBrackets > closeBrackets) {
          attemptFix += ']';
          closeBrackets++;
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

  // JSON을 WordEntry 객체로 변환 (개선된 메서드)
  WordEntry _parseWordJson(Map<String, dynamic> json) {
    // 기본 필드 추출
    final word = json['word'] ?? '';
    final pronunciation = json['pronunciation'] ?? '';
    final meaning = json['meaning'] ?? '';

    // 예문 처리
    List<String> examples = [];
    if (json['examples'] != null) {
      if (json['examples'] is List) {
        examples =
            List<String>.from(json['examples'].map((e) => e?.toString() ?? ''));
      } else if (json['examples'] is String &&
          json['examples'].toString().isNotEmpty) {
        examples = [json['examples'].toString()];
      }
    }

    // 관련 구문 처리
    List<String> commonPhrases = [];
    if (json['commonPhrases'] != null) {
      if (json['commonPhrases'] is List) {
        commonPhrases = List<String>.from(
            json['commonPhrases'].map((e) => e?.toString() ?? ''));
      } else if (json['commonPhrases'] is String &&
          json['commonPhrases'].toString().isNotEmpty) {
        commonPhrases = [json['commonPhrases'].toString()];
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
