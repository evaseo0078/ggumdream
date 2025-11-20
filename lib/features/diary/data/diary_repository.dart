//lib/features/diary/data/diary_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../domain/diary_entry.dart';

class DiaryRepository {
  final Box<DiaryEntry> _box;

  DiaryRepository(this._box);

  // 일기 목록 가져오기 (최신순 정렬)
  List<DiaryEntry> getDiaries() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // 일기 추가
  Future<void> addDiary(DiaryEntry entry) async {
    await _box.put(entry.id, entry);
  }

  // 일기 삭제
  Future<void> deleteDiary(String id) async {
    await _box.delete(id);
  }

  // 판매 상태 변경
  Future<void> toggleSellStatus(String id) async {
    final entry = _box.get(id);
    if (entry != null) {
      entry.isSold = !entry.isSold;
      entry.save(); // HiveObject의 save 메서드
    }
  }
}

// 가짜 LLM 서비스 (실제 API 연동 전 테스트용)
class MockLLMService {
  Future<String> generateImage(String prompt) async {
    await Future.delayed(const Duration(seconds: 2)); // 2초 딜레이 시뮬레이션
    // 랜덤한 꿈 관련 이미지 URL 반환 (Picsum 무료 이미지)
    return "https://picsum.photos/seed/${prompt.length}/300/300";
  }

  // ✨ mood가 포함된 이 함수 하나만 있어야 합니다!
  Future<Map<String, String>> analyzeDream(String content) async {
    await Future.delayed(const Duration(seconds: 1));

    // 간단한 키워드 기반 기분 분석 (Mock Logic)
    String mood = "🌿"; // 기본: 평온
    final lower = content.toLowerCase();

    if (lower.contains("happy") ||
        lower.contains("good") ||
        lower.contains("fly") ||
        lower.contains("joy")) {
      mood = "😊"; // 행복
    } else if (lower.contains("ghost") ||
        lower.contains("scary") ||
        lower.contains("run") ||
        lower.contains("dark")) {
      mood = "👻"; // 무서움
    } else if (lower.contains("sad") ||
        lower.contains("cry") ||
        lower.contains("tears") ||
        lower.contains("lost")) {
      mood = "💧"; // 슬픔
    } else if (lower.contains("strange") ||
        lower.contains("weird") ||
        lower.contains("alien") ||
        lower.contains("ufo")) {
      mood = "👽"; // 기묘함
    } else if (lower.contains("love") ||
        lower.contains("kiss") ||
        lower.contains("hug")) {
      mood = "❤️"; // 사랑
    }

    return {
      "summary": "Summary of: $content",
      "interpretation": "This dream reflects your subconscious feelings.",
      "mood": mood, // ✨ 기분 반환 필수
    };
  }
}
