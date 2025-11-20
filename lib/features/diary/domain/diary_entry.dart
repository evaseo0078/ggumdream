//lib/features/diary/domain/diary_entry.dart

import 'package:hive/hive.dart';

// g.dart 파일 생성은 build_runner를 돌려야 하므로,
// 여기서는 수동으로 Adapter를 등록하는 방식으로 간소화해서 짜드리겠습니다.
// (실제로는 @HiveType(typeId: 0) 등을 사용합니다.)

class DiaryEntry extends HiveObject {
  final String id;
  final DateTime date;
  String content;
  String? imageUrl; // LLM이 생성한 이미지 URL (로컬 경로 or 웹 URL)
  String? summary; // 꿈 요약
  String? interpretation; // 해몽 결과
  final String mood;
  bool isSold; // 판매 여부
  final double sleepDuration;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.imageUrl,
    this.summary,
    this.interpretation,
    this.mood = "🌿",
    this.isSold = false,
    this.sleepDuration = 7.0,
  });
}

// Hive Adapter (main.dart에서 등록 필요)
class DiaryEntryAdapter extends TypeAdapter<DiaryEntry> {
  @override
  final int typeId = 0;

  @override
  DiaryEntry read(BinaryReader reader) {
    return DiaryEntry(
      id: reader.read(),
      date: DateTime.parse(reader.read()),
      content: reader.read(),
      imageUrl: reader.read(),
      summary: reader.read(),
      interpretation: reader.read(),
      isSold: reader.read(),
      mood: reader.read(),
      sleepDuration: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, DiaryEntry obj) {
    writer.write(obj.id);
    writer.write(obj.date.toIso8601String());
    writer.write(obj.content);
    writer.write(obj.imageUrl);
    writer.write(obj.summary);
    writer.write(obj.interpretation);
    writer.write(obj.isSold);
    writer.write(obj.mood);
    writer.write(obj.sleepDuration);
  }
}
