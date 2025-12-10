// lib/features/diary/data/diary_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../domain/diary_entry.dart';
import 'package:ggumdream/services/pollinations_proxy_service.dart';

/// ---------------------------------------------------------------------------
/// 0. Gemini mood 카테고리 → 이모지 매핑
/// ---------------------------------------------------------------------------
const Map<String, String> _moodEmojiMap = {
  'joy': '😀',
  'sadness': '😢',
  'anger': '😡',
  'fear': '😱',
  'love': '🥰',
  'calm': '😌',
  'confused': '🤔',
};

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

  /// 🔹 현재 로그인 유저 기준으로 일기 실시간 스트림
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

  /// 🔹 현재 로그인 유저 기준으로 일기 1회 조회
  Future<List<DiaryEntry>> fetchDiaries() async {
    final uid = _requireUid();
    final snapshot = await _diaryCollection(uid)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DiaryEntry.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// 🔹 일기 저장/수정
  ///  - diaries 규칙:
  ///    create/update 모두 "ownerId == auth.uid" 조건을 만족해야 하므로
  ///    항상 ownerId를 현재 로그인 uid로 강제 세팅한다.
  Future<void> saveDiary(DiaryEntry entry) async {
    final uid = _requireUid();

    // DiaryEntry에서 만든 데이터에 ownerId를 강제로 덧붙여서 규칙 만족
    final data = entry.toFirestore()
      ..['ownerId'] = uid; // 🔑 rules와 일관성 유지

    await _diaryCollection(uid)
        .doc(entry.id)
        .set(data, SetOptions(merge: true));
  }

  /// 🔹 일기 삭제
  Future<void> deleteDiary(String id) async {
    final uid = _requireUid();
    await _diaryCollection(uid).doc(id).delete();
  }

  /// 🔹 판매 여부 플래그 업데이트
  ///  - 기존 규칙:
  ///    resource.data에 ownerId가 있는 경우, update에서도
  ///    request.resource.data.ownerId == resource.data.ownerId 여야 통과.
  ///  - 따라서 isSold만 보내면 막힐 수 있으므로
  ///    항상 ownerId도 함께 보내서 기존 값과 동일하게 유지.
  Future<void> setSellStatus(String id, bool isSold) async {
    final uid = _requireUid();

    await _diaryCollection(uid).doc(id).set(
      {
        'isSold': isSold,
        'ownerId': uid, // 🔑 update 시에도 ownerId 유지
      },
      SetOptions(merge: true),
    );
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
  // 2) 꿈 분석 (Gemini API 사용)
  //    - Gemini는 mood_category (joy/sadness/...)만 고르고
  //    - 앱에서 _moodEmojiMap으로 이모지로 변환
  // -------------------------------------------------------------------------
  Future<Map<String, String>> analyzeDream(String content) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        "summary": "API Key 없음",
        "interpretation": ".env 파일을 확인해주세요.",
        // 카테고리를 못 쓰는 상황이니 대충 'confused' 느낌 이모지 사용
        "mood": _moodEmojiMap['confused'] ?? '🤔',
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
Do NOT include any extra text before or after the JSON.

The mood_category must be exactly ONE of:
"joy", "sadness", "anger", "fear", "love", "calm", "confused".

JSON format:
{
  "summary": "English summary (1 sentence)",
  "interpretation": "English interpretation (warm tone, 2 sentences)",
  "mood_category": "one of: joy | sadness | anger | fear | love | calm | confused"
}
""";

      final response = await model.generateContent([
        Content.text("$systemPrompt\n\nUser's Dream: $content")
      ]);

      print("Gemini 응답 원본: ${response.text}");

      String contentString = response.text ?? "";

      // 마크다운(```json ``` ) 제거
      contentString = contentString
          .replaceAll(RegExp(r'```json', multiLine: true), '')
          .replaceAll(RegExp(r'```', multiLine: true), '')
          .trim();

      Map<String, dynamic>? contentJson;
      try {
        contentJson = jsonDecode(contentString);
      } catch (e) {
        print("Gemini 응답 파싱 실패: $contentString");
        return {
          "summary": "분석 결과를 이해할 수 없습니다.",
          "interpretation": "AI 응답이 올바른 JSON이 아닙니다.",
          "mood": _moodEmojiMap['confused'] ?? '🤔',
        };
      }

      // ---------------------------
      // 1) 안전하게 값 꺼내기
      // ---------------------------
      final summary =
          contentJson?['summary']?.toString() ?? "요약 실패";

      final interpretation =
          contentJson?['interpretation']?.toString() ?? "해석 실패";

      final rawCategory = (
              contentJson?['mood_category']?.toString() ?? ''
            )
            .toLowerCase()
            .trim();

      // 2) 카테고리를 이모지로 매핑 (없으면 confused 이모지)
      final moodEmoji =
          _moodEmojiMap[rawCategory] ?? _moodEmojiMap['confused'] ?? '🤔';

      return {
        "summary": summary,
        "interpretation": interpretation,
        "mood": moodEmoji,
      };
    } catch (e) {
      print("Gemini 분석 오류: $e");
      print("입력값: $content");
      return {
        "summary": "분석에 실패했어요",
        "interpretation": "잠시 후 다시 시도해주세요.",
        "mood": _moodEmojiMap['confused'] ?? '🤔',
      };
    }
  }
}
