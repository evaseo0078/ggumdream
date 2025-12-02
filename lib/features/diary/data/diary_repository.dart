import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart'; // Gemini SDK
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

// 2. LLM 서비스 (수정된 버전)
// 2. LLM 서비스 (수정된 버전)
class MockLLMService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  
  // Base64 이미지임을 알리는 접두어
  static const String _imagePrefix = 'data:image/png;base64,';

  // ---------------------------------------------------------
  // [수정됨] 1. 이미지 생성 (Pollinations API 사용)
  // 구글 API의 404 오류를 피하기 위해 완전 무료 API로 교체했습니다.
  // ---------------------------------------------------------
  Future<String> generateImage(String prompt) async {
    try {
      // 프롬프트가 한글일 경우를 대비해 URL 인코딩
      final encodedPrompt = Uri.encodeComponent("dreamy watercolor painting of $prompt");
      // Pollinations AI URL (API 키 필요 없음)
      final url = Uri.parse('https://image.pollinations.ai/prompt/$encodedPrompt');

      // 이미지 데이터 다운로드
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 받아온 이미지 데이터를 Base64 문자열로 변환
        final bytesBase64 = base64Encode(response.bodyBytes);
        // 접두어를 붙여서 반환 (앱에서 바로 표시 가능)
        return _imagePrefix + bytesBase64;
      }
      
      print("이미지 생성 실패 (상태코드): ${response.statusCode}");
      return "https://picsum.photos/300/300?error=api_fail";

    } catch (e) {
      print("이미지 네트워크 오류: $e");
      return "https://picsum.photos/seed/${prompt.length}/300/300?error=network"; 
    }
  }

  // ---------------------------------------------------------
  // 2. 꿈 분석 (Gemini API 사용)
  // ---------------------------------------------------------
  Future<Map<String, String>> analyzeDream(String content) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        "summary": "API Key 없음",
        "interpretation": ".env 파일을 확인해주세요.",
        "mood": "🌿",
      };
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: _apiKey,
      );

      final systemPrompt = """
        You are a dream interpreter. Analyze the user's dream.
        Respond with a valid JSON object ONLY.
        JSON format:
        {
          "summary": "한글 요약 (1문장)",
          "interpretation": "한글 해석 (따뜻한 말투, 2문장)",
          "mood": "이모지 1개"
        }
      """;

      final response = await model.generateContent([
        Content.text("$systemPrompt\n\nUser's Dream: $content")
      ]);

      print("Gemini 응답 원본: ${response.text}");

      String contentString = response.text ?? "";
      // 마크다운(```json)이 있을 경우 제거
      contentString = contentString.replaceAll(RegExp(r'```json'), '').replaceAll(RegExp(r'```'), '').trim();

      // JSON 파싱 시도, 실패하면 fallback
      Map<String, dynamic>? contentJson;
      try {
        contentJson = jsonDecode(contentString);
      } catch (e) {
        print("Gemini 응답 파싱 실패: $contentString");
        return {
          "summary": "분석 결과를 이해할 수 없습니다.",
          "interpretation": "AI 응답이 올바른 JSON이 아닙니다.",
          "mood": "❓"
        };
      }

      return {
        "summary": contentJson?['summary']?.toString() ?? "요약 실패",
        "interpretation": contentJson?['interpretation']?.toString() ?? "해석 실패",
        "mood": contentJson?['mood']?.toString() ?? "❓",
      };

    } catch (e) {
      print("Gemini 분석 오류: $e");
      print("입력값: $content");
      return {
        "summary": "분석에 실패했어요",
        "interpretation": "잠시 후 다시 시도해주세요.",
        "mood": "⚠️"
      };
    }
  }
}