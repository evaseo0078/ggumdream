import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http; // http 패키지 필요
import '../domain/diary_entry.dart';

// 1. 다이어리 저장소 (Hive 로컬 DB)
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
      entry.save(); 
    }
  }
}

// 2. LLM 서비스 (OpenAI API + Mock Fallback)
class MockLLMService {
  // 🔑 [중요] 여기에 발급받은 OpenAI API Key를 입력하세요.
  // 키가 "sk-"로 시작하지 않으면 자동으로 아래의 가짜(Mock) 로직이 실행됩니다.
  final String apiKey = "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"; 

  // ---------------------------------------------------------
  // 1. 이미지 생성 (DALL-E 3)
  // ---------------------------------------------------------
  Future<String> generateImage(String prompt) async {
    // API 키가 없거나 기본값이면 -> 무료 랜덤 이미지 반환
    if (!apiKey.startsWith("sk-")) {
      await Future.delayed(const Duration(seconds: 2));
      return "https://picsum.photos/seed/${prompt.length}/300/300";
    }

    // 실제 API 호출
    final url = Uri.parse('https://api.openai.com/v1/images/generations');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-exp:free', // 고품질 모델
          'prompt': 'A warm, dreamy, and artistic illustration of: $prompt',
          'n': 1,
          'size': '1024x1024'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'][0]['url'];
      } else {
        print("OpenAI Image Error: ${response.body}");
        return "https://picsum.photos/300/300"; // 에러 시 기본 이미지
      }
    } catch (e) {
      print("Network Error: $e");
      return "https://picsum.photos/300/300";
    }
  }

  // ---------------------------------------------------------
  // 2. 꿈 분석 (GPT-4o-mini)
  // ---------------------------------------------------------
  Future<Map<String, String>> analyzeDream(String content) async {
    // API 키가 없거나 기본값이면 -> 키워드 기반 가짜 분석 (Mock Logic)
    if (!apiKey.startsWith("sk-")) {
      await Future.delayed(const Duration(seconds: 1));
      
      String mood = "🌿"; // 기본: 평온
      final lower = content.toLowerCase();

      if (lower.contains("happy") || lower.contains("good") || lower.contains("fly") || lower.contains("joy")) {
        mood = "😊"; // 행복
      } else if (lower.contains("ghost") || lower.contains("scary") || lower.contains("run") || lower.contains("dark")) {
        mood = "👻"; // 무서움
      } else if (lower.contains("sad") || lower.contains("cry") || lower.contains("tears") || lower.contains("lost")) {
        mood = "💧"; // 슬픔
      } else if (lower.contains("strange") || lower.contains("weird") || lower.contains("alien") || lower.contains("ufo")) {
        mood = "👽"; // 기묘함
      } else if (lower.contains("love") || lower.contains("kiss") || lower.contains("hug")) {
        mood = "❤️"; // 사랑
      }

      return {
        "summary": "Summary of: $content (Mock)",
        "interpretation": "This dream reflects your subconscious feelings. (Mock)",
        "mood": mood,
      };
    }

    // 실제 API 호출
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini", // 가성비 모델
          "messages": [
            {
              "role": "system",
              // ✨ [핵심] 기분을 이모지 1개로 달라고 명시
              "content": """
                You are a dream interpreter. Analyze the user's dream.
                Return ONLY a JSON object with these keys:
                - 'summary': A short 1-sentence summary.
                - 'interpretation': A warm 2-sentence interpretation.
                - 'mood': A single emoji representing the dominant emotion (e.g., 🌿, 👻, 😊, 💧, 🔥).
              """
            },
            {
              "role": "user",
              "content": content
            }
          ],
          "response_format": { "type": "json_object" } // JSON 강제
        }),
      );

      if (response.statusCode == 200) {
        // 한글 깨짐 방지 디코딩
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final contentString = data['choices'][0]['message']['content'];
        final contentJson = jsonDecode(contentString);
        
        return {
          "summary": contentJson['summary'] ?? "No summary",
          "interpretation": contentJson['interpretation'] ?? "No interpretation",
          "mood": contentJson['mood'] ?? "🌿",
        };
      } else {
         print("OpenAI Chat Error: ${response.body}");
         return {
          "summary": "Analysis failed",
          "interpretation": "Could not connect to AI service.",
          "mood": "❓"
        };
      }
    } catch (e) {
      print("Network Error: $e");
      return {
        "summary": "Network Error",
        "interpretation": "Check your internet connection.",
        "mood": "📶"
      };
    }
  }
}