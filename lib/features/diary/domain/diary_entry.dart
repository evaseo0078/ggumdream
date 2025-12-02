// lib/features/diary/domain/diary_entry.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for a diary entry stored in Firestore.
class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
  final String? imageUrl;
  final String? summary;
  final String? interpretation;
  final String mood;
  final double sleepDuration;
  final bool isSold;
  final bool isDraft; // 임시저장 여부

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.imageUrl,
    this.summary,
    this.interpretation,
    this.mood = '🙂',
    this.sleepDuration = 7.0,
    this.isSold = false,
    this.isDraft = false,
  });

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? imageUrl,
    String? summary,
    String? interpretation,
    String? mood,
    double? sleepDuration,
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
      isSold: isSold ?? this.isSold,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'content': content,
      'imageUrl': imageUrl,
      'summary': summary,
      'interpretation': interpretation,
      'mood': mood,
      'sleepDuration': sleepDuration,
      'isSold': isSold,
      'isDraft': isDraft,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory DiaryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    final rawDate = data['date'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return DiaryEntry(
      id: id,
      date: parsedDate,
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      summary: data['summary'] as String?,
      interpretation: data['interpretation'] as String?,
      mood: data['mood'] as String? ?? '🙂',
      sleepDuration:
          (data['sleepDuration'] is num) ? (data['sleepDuration'] as num).toDouble() : 7.0,
      isSold: data['isSold'] as bool? ?? false,
      isDraft: data['isDraft'] as bool? ?? false,
    );
  }
}
