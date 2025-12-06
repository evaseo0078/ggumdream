import 'dart:convert';
import 'dart:developer'; // 로그 출력을 위해 사용
import 'dart:typed_data'; // Uint8List 사용을 위해 추가
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 파일 사용을 위해 추가
import 'package:http/http.dart' as http;

class GeminiService {
  // .env 파일에서 GEMINI_API_KEY를 가져옵니다.
  // main.dart에서 await dotenv.load(fileName: ".env"); 가 먼저 호출되어야 합니다.
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // 사용할 모델 (gemini-1.5-flash)
  static const String _model = 'gemini-1.5-flash';
  
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// 텍스트 메시지를 보내고 응답을 받습니다.
  Future<String?> sendMessage(String message) async {
    return _callGeminiAPI([
      {"text": message}
    ]);
  }

  /// 꿈 스케치(이미지)를 분석하여 해석을 요청합니다.
  Future<String?> analyzeDreamSketch(Uint8List imageBytes) async {
    // 이미지를 Base64 문자열로 인코딩
    String base64Image = base64Encode(imageBytes);

    return _callGeminiAPI([
      {"text": "이 그림은 사용자가 그린 꿈의 스케치입니다. 이 그림이 무엇을 묘사하고 있는지 분석하고, 꿈 해몽 관점에서 어떤 의미가 있을지 부드럽고 몽환적인 어조로 해석해주세요."},
      {
        "inline_data": {
          "mime_type": "image/png", // toPngBytes()를 사용하므로 png로 설정
          "data": base64Image
        }
      }
    ]);
  }

  /// 내부적으로 Gemini API를 호출하는 공통 메서드
  Future<String?> _callGeminiAPI(List<Map<String, dynamic>> parts) async {
    if (_apiKey.isEmpty) {
      log('Gemini Error: API Key가 설정되지 않았습니다. .env 파일을 확인해주세요.');
      return "API 설정 오류가 발생했습니다.";
    }

    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": parts
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null) {
              
          final String responseText = data['candidates'][0]['content']['parts'][0]['text'];
          return responseText;
        } else {
          log('Gemini Error: 유효한 응답 텍스트가 없습니다.');
          return null;
        }
      } else {
        log('Gemini API Error: ${response.statusCode} - ${response.body}');
        return "오류가 발생했습니다. (상태 코드: ${response.statusCode})";
      }
    } catch (e) {
      log('Exception calling Gemini API: $e');
      return "네트워크 오류가 발생했습니다: $e";
    }
  }
}