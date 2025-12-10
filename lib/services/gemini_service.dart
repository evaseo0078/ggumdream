// gemini_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// 🔥 Gemini 쿼터 초과 시 던지는 예외
class GeminiQuotaExceededException implements Exception {
  final String message;
  GeminiQuotaExceededException([this.message = '']);

  @override
  String toString() => 'GeminiQuotaExceededException: $message';
}

class GeminiService {
  // .env load check
  static String get _apiKey {
    // Use whichever key name exists
    final key =
        dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY_2'] ?? '';
    if (key.isEmpty) {
      log('🚨 [CRITICAL] Failed to read API key from .env! Check main.dart configuration.');
    } else {
      log('✅ API key loaded (prefix: ${key.substring(0, 4)}...)');
    }
    return key;
  }

  // Model setup
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String?> analyzeDreamSketch(Uint8List imageBytes) async {
    final key = _apiKey;
    if (key.isEmpty) {
      return "Configuration error: Missing API key (see logs).";
    }

    log('📸 Image size: ${imageBytes.lengthInBytes} bytes');
    final base64Image = base64Encode(imageBytes);

    try {
      final url = Uri.parse('$_baseUrl?key=$key');

      // Build request body
      final requestBody = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "This image is a sketch of the user's dream. Describe the scene briefly and gently interpret its symbolic meaning from a dream analysis perspective. Keep the response to a single paragraph under 60 words (approx. 300–400 characters). Be concise and focus only on the essentials."
              },
              {
                "inline_data": {
                  "mime_type": "image/png",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "maxOutputTokens": 1024,
          "topK": 40,
          "topP": 0.8,
        }
      });

      log('🚀 Sending request...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      log('📡 Status code: ${response.statusCode}');
      log('📡 Response body: ${response.body}');

      // ----------------------------
      // 200 OK: 정상 처리
      // ----------------------------
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            (data['candidates'] as List).isNotEmpty) {
          final candidate = data['candidates'][0];

          // 1. Normal text extraction
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              (candidate['content']['parts'] as List).isNotEmpty) {
            final txt = candidate['content']['parts'][0]['text'] ?? '';
            return _truncateToRange(txt);
          }

          // 2. If still stopped due to MAX_TOKENS or others
          if (candidate['finishReason'] != null) {
            final reason = candidate['finishReason'];
            if (reason == 'MAX_TOKENS') {
              if (candidate['content'] != null &&
                  candidate['content']['parts'] != null) {
                final partial =
                    candidate['content']['parts'][0]['text'] ?? '';
                final clipped = _truncateToRange(partial);
                return clipped.isNotEmpty ? clipped : _fallbackSummary();
              }
              return _fallbackSummary();
            }
            // other finish reasons → generic fallback
            return _fallbackSummary();
          }
        }

        return _fallbackSummary();
      }

      // ----------------------------
      // 200이 아닌 모든 응답 처리
      // 여기서 "쿼터 초과"를 캐치해서 예외로 던짐
      // ----------------------------
      log('❌ [ERROR BODY]: ${response.body}');

      String? errorMessage;
      try {
        final err = jsonDecode(response.body);
        errorMessage = err['error']?['message']?.toString();
      } catch (_) {
        // ignore JSON parse error
      }

      final msgLower = (errorMessage ?? '').toLowerCase();

      final isQuotaError =
          response.statusCode == 429 || // Too Many Requests
          msgLower.contains('quota') ||
          msgLower.contains('rate limit') ||
          msgLower.contains('resource_exhausted');

      if (isQuotaError) {
        // 👉 UI에서 팝업을 띄울 수 있도록 예외 전달
        throw GeminiQuotaExceededException(errorMessage ?? 'Quota exceeded');
      }

      // 그 외 에러는 조용히 fallback 제공
      return _fallbackSummary();
    } catch (e) {
      // 네트워크/기타 예외
      log('💥 Network exception in analyzeDreamSketch: $e');
      return _fallbackSummary();
    }
  }

  Future<String?> sendMessage(String message) async {
    return "Image analysis only.";
  }

  // Helper to clamp output to ~300–400 chars
  String _truncateToRange(
    String input, {
    int minChars = 280,
    int maxChars = 420,
  }) {
    final trimmed = input.trim().replaceAll('\n', ' ');
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    final cut = trimmed.substring(0, maxChars);
    final lastPeriod = cut.lastIndexOf('.');
    final lastKoreanPeriod = cut.lastIndexOf('。');
    final boundary = [lastPeriod, lastKoreanPeriod]
        .where((i) => i >= minChars)
        .fold(-1, (a, b) => a > b ? a : b);

    if (boundary >= minChars) {
      return cut.substring(0, boundary + 1).trim();
    }

    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace >= minChars) {
      return cut.substring(0, lastSpace).trim() + '…';
    }
    return cut.trim() + '…';
  }

  // Friendly, generic fallback summary to avoid showing errors
  String _fallbackSummary() {
    const fallback =
        "A gentle, dreamy impression: this sketch suggests themes of emotion and reflection, hinting at inner desires and memories. It invites calm self-observation and soft acceptance of change.";
    return _truncateToRange(fallback, minChars: 200, maxChars: 420);
  }
}
