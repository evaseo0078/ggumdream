import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class OcrService {
  late final GenerativeModel _model;

  OcrService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  /// 이미지 경로를 받아 최적화 후 Gemini에게 텍스트 인식을 요청
  Future<String> processImageFromPath(String imagePath) async {
    try {
      // 1. 이미지 압축 (저사양 태블릿 필수 최적화)
      // 원본 이미지가 너무 크면 전송이 느리고 메모리가 터질 수 있음 -> 1024px로 리사이징
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 70, // 화질을 조금 낮춰 전송 속도 향상
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) throw Exception('이미지 압축 실패');

      // 2. 프롬프트 작성 (영어 손글씨 특화 + 오타 보정 요청)
      final content = [
        Content.multi([
          TextPart('Please read the handwritten English text in this image. '
              'Correct any obvious spelling mistakes based on context. '
              'Output ONLY the raw text without any markdown formatting or explanations.'),
          DataPart('image/jpeg', compressedBytes),
        ])
      ];

      // 3. Gemini API 호출
      final response = await _model.generateContent(content);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return '텍스트를 인식하지 못했습니다.';
      }
      
      print('Recognized text:');
      print(text);
      
      return text;
    } catch (e) {
      print('OCR processing error: $e');
      
      // 에러 메시지를 사용자에게 보여줄 수 있도록 간단히 가공
      if (e.toString().contains('API_KEY')) {
        throw Exception('API 키가 설정되지 않았습니다.');
      }
      rethrow;
    }
  }

  void dispose() {
    // Gemini 모델은 특별한 리소스 해제가 필요 없습니다.
  }
}
