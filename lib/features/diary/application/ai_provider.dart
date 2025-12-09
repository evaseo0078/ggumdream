// lib/features/diary/application/ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/gemini_service.dart';

// 앱 어디서든 ref.read(geminiServiceProvider)로 불러올 수 있게 함
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
