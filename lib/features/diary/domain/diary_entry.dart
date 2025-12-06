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

  // ------------------------------------------------------------
  // ✅ Dream day 계산 (cutoff 18:00)
  // ------------------------------------------------------------
  DateTime logicalDay({int cutoffHour = 18}) {
    final d = date;
    final base = DateTime(d.year, d.month, d.day);

    final hasTimeInfo =
        d.hour != 0 || d.minute != 0 || d.second != 0 || d.millisecond != 0;

    // 날짜만 저장된 값이면 그대로 사용
    if (!hasTimeInfo) return base;

    // 18:00 이전이면 전날 dream day
    if (d.hour < cutoffHour) {
      return base.subtract(const Duration(days: 1));
    }
    return base;
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
      'sleepStartAt': sleepStartAt == null ? null : Timestamp.fromDate(sleepStartAt!),
      'sleepEndAt': sleepEndAt == null ? null : Timestamp.fromDate(sleepEndAt!),
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
