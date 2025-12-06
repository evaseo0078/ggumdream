import 'dart:convert';
import 'dart:developer'; // 로그 출력용
import 'dart:typed_data'; // 이미지 데이터 처리용
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 환경변수
import 'package:http/http.dart' as http;

class GeminiService {
  // .env 파일에서 키 로드
  static String get _apiKey => dotenv.env['GEMINI_API_KEY_2'] ?? '';

  // 모델 설정 (안정적인 1.5 Flash 사용)
  static const String _model = 'gemini-2.5-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// 텍스트 대화 요청
  Future<String?> sendMessage(String message) async {
    return _callGeminiAPI([
      {"text": message}
    ]);
  }

  /// 꿈 스케치 분석 요청
  Future<String?> analyzeDreamSketch(Uint8List imageBytes) async {
    String base64Image = base64Encode(imageBytes);

    return _callGeminiAPI([
      {
        "text":
            "이 그림은 사용자가 꾼 꿈의 장면을 스케치한 것입니다. 이 그림이 무엇을 묘사하고 있는지 자세히 설명하고, 꿈 해몽 관점에서 이 이미지가 상징하는 심리적 의미를 부드럽고 몽환적인 말투로 해석해주세요."
      },
      {
        "inline_data": {"mime_type": "image/png", "data": base64Image}
      }
    ]);
  }

  /// API 호출 핵심 로직 (재시도 & 안전 설정 포함)
  Future<String?> _callGeminiAPI(List<Map<String, dynamic>> parts) async {
    if (_apiKey.isEmpty) {
      log('Gemini Error: API Key 없음');
      return "설정 오류: API 키가 없습니다.";
    }

    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount <= maxRetries) {
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {"parts": parts}
            ],
            // 안전 설정: 그림 분석 시 차단 방지
            "safetySettings": [
              {
                "category": "HARM_CATEGORY_HARASSMENT",
                "threshold": "BLOCK_ONLY_HIGH"
              },
              {
                "category": "HARM_CATEGORY_HATE_SPEECH",
                "threshold": "BLOCK_ONLY_HIGH"
              },
              {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_ONLY_HIGH"
              },
              {
                "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                "threshold": "BLOCK_ONLY_HIGH"
              }
            ],
            "generationConfig": {
              "temperature": 0.7,
              // ✨ 중요: 기존 1024 -> 4096으로 변경 (MAX_TOKENS 에러 해결)
              "maxOutputTokens": 4096,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final candidate = data['candidates'][0];

            // 정상 응답
            if (candidate['content'] != null &&
                candidate['content']['parts'] != null &&
                candidate['content']['parts'].isNotEmpty) {
              return candidate['content']['parts'][0]['text'];
            }
            // 안전 필터나 기타 사유로 차단된 경우
            else if (candidate['finishReason'] != null) {
              // MAX_TOKENS 에러가 여기서 잡힐 수도 있습니다.
              if (candidate['finishReason'] == 'MAX_TOKENS') {
                // 혹시라도 4096도 넘기면 부분만이라도 리턴 시도
                return "답변이 너무 길어 중간에 끊겼습니다. (MAX_TOKENS)";
              }
              return "답변이 차단되었습니다. (사유: ${candidate['finishReason']})";
            }
          }
          return "해석 결과를 가져올 수 없습니다.";
        }

        // 429 에러 (Too Many Requests) 처리
        else if (response.statusCode == 429) {
          log('Gemini 429 Error. 재시도 중... ($retryCount/$maxRetries)');
          retryCount++;
          if (retryCount > maxRetries)
            return "사용량이 많아 지연되고 있습니다. 잠시 후 다시 시도해주세요.";
          await Future.delayed(Duration(seconds: (1 << retryCount)));
          continue;
        } else {
          log('Gemini API Error: ${response.statusCode}');
          return "서버 오류: ${response.statusCode}";
        }
      } catch (e) {
        log('Exception: $e');
        return "네트워크 오류: $e";
      }
    }
    return "요청 실패";
  }
}
