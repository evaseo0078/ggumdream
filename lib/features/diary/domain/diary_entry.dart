import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for a diary entry stored in Firestore.
class DiaryEntry {
  final String id;
  final DateTime date;

  final String content;
  final String? imageUrl;
  final String? summary;
  final String? interpretation;

  /// mood emoji
  final String mood;

  /// Sleep duration in hours
  /// -1.0 means "unknown"
  final double sleepDuration;

  final bool isSold;
  final bool isDraft;

  /// Optional explicit sleep interval
  final DateTime? sleepStartAt;
  final DateTime? sleepEndAt;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.imageUrl,
    this.summary,
    this.interpretation,
    this.mood = '🙂',
    this.sleepDuration = -1.0, // ✅ default unknown
    this.sleepStartAt,
    this.sleepEndAt,
    this.isSold = false,
    this.isDraft = false,
  }) : assert(
          sleepDuration == -1.0 || sleepDuration >= 0,
          'sleepDuration must be -1.0 (unknown) or >= 0',
        );

  // ------------------------------------------------------------
  // ✅ Compatibility getters (Stats/old code safe)
  // ------------------------------------------------------------
  double get sleepDurationInHours => sleepDuration;

  bool get hasSleepInterval => sleepStartAt != null && sleepEndAt != null;

  // ------------------------------------------------------------
  // ✅ Dream day 계산 (cutoff 18:00)
  // - "꿈 기록이 붙는 날짜" 기준
  //
  // ✅ 핵심:
  // 1) 수면 구간이 있으면 sleepEndAt(기상 시각)을 기준으로 날짜 판단
  //    -> 6일 23-07 입력 시
  //       실제 interval: 5일 23:00 ~ 6일 07:00 저장이어도
  //       꿈 기록/마커는 6일에 붙게 유도 가능
  //
  // 2) 날짜-only(00:00:00)는 보정 금지
  // ------------------------------------------------------------
  DateTime logicalDay({int cutoffHour = 18}) {
    // ✅ 수면 구간이 있으면 "기상 시각"을 우선 기준으로
    final ref = sleepEndAt ?? date;

    final base = DateTime(ref.year, ref.month, ref.day);

    // ✅ 날짜-only 판단 (캘린더에서 선택한 날짜가 여기에 해당)
    final isDateOnly = ref.hour == 0 &&
        ref.minute == 0 &&
        ref.second == 0 &&
        ref.millisecond == 0 &&
        ref.microsecond == 0;

    if (isDateOnly) return base;

    // ✅ 일반 케이스만 cutoff 적용
    if (ref.hour < cutoffHour) {
      return base.subtract(const Duration(days: 1));
    }
    return base;
  }

  // ------------------------------------------------------------
  // ✅ Sleep logical day 계산
  // - "수면 기록이 캘린더/스탯에서 붙는 날짜" 기준
  //
  // ✅ 너의 요구사항:
  //   6일 23-07 입력 → 실제 interval이
  //   5일 23:00 ~ 6일 07:00 으로 저장되더라도
  //   "6일 logical day에 붙게"
  //
  // => sleepEndAt(기상 시각)의 날짜를 기준으로 고정
  // ------------------------------------------------------------
  DateTime sleepLogicalDay({int cutoffHour = 18}) {
    if (sleepEndAt != null) {
      final e = sleepEndAt!;
      return DateTime(e.year, e.month, e.day);
    }

    // fallback: date 기준 (날짜-only면 그대로)
    final d = date;
    return DateTime(d.year, d.month, d.day);
  }

  // ------------------------------------------------------------
  // copyWith
  // ------------------------------------------------------------
  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? imageUrl,
    String? summary,
    String? interpretation,
    String? mood,
    double? sleepDuration,
    DateTime? sleepStartAt,
    DateTime? sleepEndAt,
    bool? isSold,
    bool? isDraft,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      summary: summary ?? this.summary,
      interpretation: interpretation ?? this.interpretation,
      mood: mood ?? this.mood,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      sleepStartAt: sleepStartAt ?? this.sleepStartAt,
      sleepEndAt: sleepEndAt ?? this.sleepEndAt,
      isSold: isSold ?? this.isSold,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  // ------------------------------------------------------------
  // Firestore serialize
  // ------------------------------------------------------------
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'content': content,
      'imageUrl': imageUrl,
      'summary': summary,
      'interpretation': interpretation,
      'mood': mood,
      'sleepDuration': sleepDuration,
      'sleepStartAt':
          sleepStartAt == null ? null : Timestamp.fromDate(sleepStartAt!),
      'sleepEndAt':
          sleepEndAt == null ? null : Timestamp.fromDate(sleepEndAt!),
      'isSold': isSold,
      'isDraft': isDraft,
      'updatedAt': FieldValue.serverTimestamp(),
      // 'createdAt': FieldValue.serverTimestamp(), // 필요하면 활성화
    };
  }

  factory DiaryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    // date parse
    final rawDate = data['date'];
    DateTime parsedDate;

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // sleepDuration parse
    final rawSleep = data['sleepDuration'];
    double parsedSleep;
    if (rawSleep is num) {
      parsedSleep = rawSleep.toDouble();
      if (parsedSleep < 0) parsedSleep = -1.0; // ✅ 안전 보정
    } else {
      parsedSleep = -1.0;
    }

    // sleepStartAt / sleepEndAt parse
    DateTime? parsedStart;
    final rawStart = data['sleepStartAt'];
    if (rawStart is Timestamp) {
      parsedStart = rawStart.toDate();
    } else if (rawStart is String) {
      parsedStart = DateTime.tryParse(rawStart);
    }

    DateTime? parsedEnd;
    final rawEnd = data['sleepEndAt'];
    if (rawEnd is Timestamp) {
      parsedEnd = rawEnd.toDate();
    } else if (rawEnd is String) {
      parsedEnd = DateTime.tryParse(rawEnd);
    }

    return DiaryEntry(
      id: id,
      date: parsedDate,
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      summary: data['summary'] as String?,
      interpretation: data['interpretation'] as String?,
      mood: data['mood'] as String? ?? '🙂',
      sleepDuration: parsedSleep,
      sleepStartAt: parsedStart,
      sleepEndAt: parsedEnd,
      isSold: data['isSold'] as bool? ?? false,
      isDraft: data['isDraft'] as bool? ?? false,
    );
  }
}
