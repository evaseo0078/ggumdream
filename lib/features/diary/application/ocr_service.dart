import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// 이미지 파일 경로로부터 텍스트를 추출
  Future<String> processImageFromPath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      print('인식된 텍스트:');
      print(recognizedText.text);

      return recognizedText.text;
    } catch (e) {
      print('OCR 처리 중 오류: $e');
      rethrow;
    }
  }

  /// 리소스 정리
  void dispose() {
    _textRecognizer.close();
  }
}
