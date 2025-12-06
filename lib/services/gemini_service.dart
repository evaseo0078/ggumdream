import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // .env 로드 확인
  static String get _apiKey {
    // 키 이름이 GEMINI_API_KEY 인지 _2 인지 확인하여 존재하는 것 사용
    final key =
        dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY_2'] ?? '';
    if (key.isEmpty) {
      log('🚨 [CRITICAL] .env 파일에서 키를 읽지 못했습니다! main.dart 설정을 확인하세요.');
    } else {
      log('✅ API Key 로드 성공 (키 일부: ${key.substring(0, 4)}...)');
    }
    return key;
  }

  // 모델 설정 (안정적인 1.5 Flash 사용 권장)
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String?> analyzeDreamSketch(Uint8List imageBytes) async {
    final key = _apiKey;
    if (key.isEmpty) return "API 키 설정 오류 (로그 확인 필요)";

    log('📸 이미지 데이터 크기: ${imageBytes.lengthInBytes} bytes');
    String base64Image = base64Encode(imageBytes);

    try {
      final url = Uri.parse('$_baseUrl?key=$key');

      // 3. 요청 본문 구성
      final requestBody = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                // 프롬프트에서 답변 길이를 자연어로 제어하는 것이 더 좋습니다.
                "text":
                    "이 이미지는 사용자의 꿈을 스케치한 것입니다. 스케치가 묘사하는 장면을 설명하고, 꿈 해몽 관점에서 상징적 의미를 부드럽게 해석해주세요. 답변은 3~4문장 정도로 자연스럽게 마무리해주세요."
              },
              {
                "inline_data": {"mime_type": "image/png", "data": base64Image}
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          // ✨ 중요: MAX_TOKENS 에러 해결을 위해 값을 대폭 늘립니다. (200 -> 2048)
          // 답변이 짧아도 여유 공간이 있어야 말을 끝까지 맺습니다.
          "maxOutputTokens": 2048,
        }
      });

      log('🚀 요청 전송 시작...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      log('📡 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            (data['candidates'] as List).isNotEmpty) {
          final candidate = data['candidates'][0];

          // 1. 정상 텍스트 추출
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              (candidate['content']['parts'] as List).isNotEmpty) {
            return candidate['content']['parts'][0]['text'];
          }

          // 2. 여전히 MAX_TOKENS 등으로 멈춘 경우
          if (candidate['finishReason'] != null) {
            final reason = candidate['finishReason'];
            if (reason == 'MAX_TOKENS') {
              // 혹시라도 텍스트가 일부 있다면 그거라도 반환
              if (candidate['content'] != null &&
                  candidate['content']['parts'] != null) {
                return (candidate['content']['parts'][0]['text'] ?? "") +
                    "...(길이 제한으로 중단)";
              }
              return "답변이 너무 길어 중단되었습니다. (MAX_TOKENS)";
            }
            return "답변이 차단되었습니다. (사유: $reason)";
          }
        }
        return "분석 결과 없음";
      } else {
        // 에러 발생 시 로그 출력
        log('❌ [ERROR BODY]: ${response.body}');

        final errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['error']['message'] ?? '알 수 없는 오류';
        return "오류(${response.statusCode}): $errorMessage";
      }
    } catch (e) {
      log('💥 네트워크 예외 발생: $e');
      return "네트워크 오류: $e";
    }
  }

  Future<String?> sendMessage(String message) async {
    return "그림 분석 전용입니다.";
  }
}
