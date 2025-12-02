import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/diary_entry.dart';

class DiaryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DiaryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _diaryCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('diaries');
  }

  Stream<List<DiaryEntry>> watchDiaries() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _diaryCollection(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DiaryEntry.fromFirestore(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<List<DiaryEntry>> fetchDiaries() async {
    final uid = _requireUid();
    final snapshot = await _diaryCollection(uid)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntry.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> saveDiary(DiaryEntry entry) async {
    final uid = _requireUid();
    await _diaryCollection(uid)
        .doc(entry.id)
        .set(entry.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteDiary(String id) async {
    final uid = _requireUid();
    await _diaryCollection(uid).doc(id).delete();
  }

  Future<void> setSellStatus(String id, bool isSold) async {
    final uid = _requireUid();
    await _diaryCollection(uid).doc(id).update({'isSold': isSold});
  }
}

// 2. LLM Mock Service (with optional real API)
class MockLLMService {
  final String apiKey;

  MockLLMService({String? apiKey})
      : apiKey = apiKey ?? const String.fromEnvironment('OPENAI_API_KEY');

  bool get _hasApiKey => apiKey.isNotEmpty && apiKey.startsWith('sk-');

  Future<String> generateImage(String prompt) async {
    if (!_hasApiKey) {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'https://picsum.photos/seed/${Uri.encodeComponent(prompt)}/300/300';
    }

    final url = Uri.parse('https://api.openai.com/v1/images/generations');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-image-1',
          'prompt': 'A warm, dreamy illustration of: $prompt',
          'n': 1,
          'size': '1024x1024',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>;
        return list.first['url'] as String;
      }
    } catch (_) {
      // swallow errors and fall back
    }

    return 'https://picsum.photos/seed/${Uri.encodeComponent(prompt)}/300/300';
  }

  Future<Map<String, String>> analyzeDream(String content) async {
    if (!_hasApiKey) {
      await Future.delayed(const Duration(milliseconds: 500));

      String mood = '🙂';
      final lower = content.toLowerCase();
      if (lower.contains('happy') || lower.contains('good')) {
        mood = '😄';
      } else if (lower.contains('scary') || lower.contains('ghost')) {
        mood = '😨';
      } else if (lower.contains('sad') || lower.contains('cry')) {
        mood = '😢';
      }

      return {
        'summary': 'Summary of: $content (mock)',
        'interpretation':
            'This dream reflects your subconscious feelings. (mock)',
        'mood': mood,
      };
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Return a JSON object with keys summary, interpretation, and mood (emoji) describing the dream.',
            },
            {'role': 'user', 'content': content},
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final contentString =
            (data['choices'] as List<dynamic>).first['message']['content']
                as String;
        final contentJson = jsonDecode(contentString) as Map<String, dynamic>;

        return {
          'summary': contentJson['summary'] as String? ?? 'No summary',
          'interpretation':
              contentJson['interpretation'] as String? ?? 'No interpretation',
          'mood': contentJson['mood'] as String? ?? '🙂',
        };
      }
    } catch (_) {
      // swallow and fallback
    }

    return {
      'summary': 'Analysis failed',
      'interpretation': 'Could not connect to AI service.',
      'mood': '😴',
    };
  }
}
