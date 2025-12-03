import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../domain/diary_entry.dart';
import 'package:ggumdream/services/pollinations_proxy_service.dart';

/// ---------------------------------------------------------------------------
/// 1. 일기 리포지토리 (Firestore)
/// ---------------------------------------------------------------------------
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

/// ---------------------------------------------------------------------------
/// 2. LLM 서비스 (Pollinations → Cloud Functions 경유 + Gemini 분석)
/// ---------------------------------------------------------------------------
class MockLLMService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  // -------------------------------------------------------------------------
  // 1) 이미지 생성
  //  - Flutter 앱 → Cloud Functions(generateImageFromPollinations)
  //  - Functions가 Pollinations 호출 + Firebase Storage에 저장
  //  - 여기서는 Storage 이미지 URL을 그대로 리턴
  // -------------------------------------------------------------------------
  Future<String> generateImage(String prompt) async {
    try {
      // 프롬프트 조금 꾸며서 전달 (취향대로 바꿔도 됨)
      final refinedPrompt = "dreamy watercolor painting of $prompt";

      // 서버 우회 호출 (직접 Pollinations를 부르지 않음)
      final imageUrl =
          await PollinationsProxyService.generateImage(refinedPrompt);

      return imageUrl; // Firebase Storage의 HTTPS 이미지 URL
    } catch (e) {
      print("이미지 생성 오류 (서버 우회 방식): $e");
      // 완전히 실패하면 대체 이미지
      return "https://picsum.photos/300/300?error=proxy_fail";
    }
  }

  // -------------------------------------------------------------------------
  // 2) 꿈 분석 (Gemini API 사용) – 기존 로직 그대로
  // -------------------------------------------------------------------------
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
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      final systemPrompt = """
        You are a dream interpreter. Analyze the user's dream.
        Respond with a valid JSON object ONLY.
        JSON format:
        {
          "summary": "English summary (1 sentence)",
          "interpretation": "English interpretation (warm tone, 2 sentences)",
          "mood": "1 emoji"
        }
      """;

      final response = await model.generateContent([
        Content.text("$systemPrompt\n\nUser's Dream: $content")
      ]);

      print("Gemini 응답 원본: ${response.text}");

      String contentString = response.text ?? "";
      // 마크다운(```json ``` ) 제거
      contentString = contentString
          .replaceAll(RegExp(r'```json'), '')
          .replaceAll(RegExp(r'```'), '')
          .trim();

      Map<String, dynamic>? contentJson;
      try {
        contentJson = jsonDecode(contentString);
      } catch (e) {
        print("Gemini 응답 파싱 실패: $contentString");
        return {
          "summary": "분석 결과를 이해할 수 없습니다.",
          "interpretation": "AI 응답이 올바른 JSON이 아닙니다.",
          "mood": "❓",
        };
      }

      return {
        "summary": contentJson?['summary']?.toString() ?? "요약 실패",
        "interpretation":
            contentJson?['interpretation']?.toString() ?? "해석 실패",
        "mood": contentJson?['mood']?.toString() ?? "❓",
      };
    } catch (e) {
      print("Gemini 분석 오류: $e");
      print("입력값: $content");
      return {
        "summary": "분석에 실패했어요",
        "interpretation": "잠시 후 다시 시도해주세요.",
        "mood": "⚠️",
      };
    }
  }
}
