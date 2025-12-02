// lib/services/pollinations_proxy_service.dart
import 'package:cloud_functions/cloud_functions.dart';

class PollinationsProxyService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  /// Cloud Function 호출해서 이미지 생성 후 URL 반환
  static Future<String> generateImage(String prompt) async {
    final callable =
        _functions.httpsCallable('generateImageFromPollinations');

    final result = await callable.call(<String, dynamic>{
      'prompt': prompt,
    });

    final data = result.data as Map<String, dynamic>;
    // data = { prompt: ..., path: 'pollinations/xxx.png', imageUrl: 'https://...' }

    return data['imageUrl'] as String;
  }
}
