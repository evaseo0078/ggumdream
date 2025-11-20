// lib/debug/hive_debug.dart

import 'package:hive/hive.dart';
import 'dart:convert';

/// 개발자용 Hive 디버그 유틸리티
class HiveDebug {
  /// diary_entries 박스의 모든 데이터 출력
  static void printDiaryEntries() {
    final box = Hive.box<Map>('diary_entries');
    print('\n=== Diary Entries (${box.length} items) ===');

    for (var key in box.keys) {
      final entry = box.get(key);
      print('\n--- Entry: $key ---');
      print(jsonEncode(entry));
    }
    print('=== End of Diary Entries ===\n');
  }

  /// purchased_diaries 박스의 모든 데이터 출력
  static void printPurchasedDiaries() {
    final box = Hive.box<Map>('purchased_diaries');
    print('\n=== Purchased Diaries (${box.length} items) ===');

    for (var key in box.keys) {
      final entry = box.get(key);
      print('\n--- Purchase: $key ---');
      print(jsonEncode(entry));
    }
    print('=== End of Purchased Diaries ===\n');
  }

  /// 모든 Hive 박스 데이터 출력
  static void printAllData() {
    printDiaryEntries();
    printPurchasedDiaries();
  }

  /// 특정 박스의 특정 키 데이터 출력
  static void printEntry(String boxName, String key) {
    try {
      final box = Hive.box<Map>(boxName);
      final entry = box.get(key);
      print('\n=== $boxName[$key] ===');
      print(jsonEncode(entry));
      print('=== End ===\n');
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 특정 엔트리 수정 (디버그용)
  static Future<void> updateEntry(
    String boxName,
    String key,
    Map<String, dynamic> newData,
  ) async {
    try {
      final box = Hive.box<Map>(boxName);
      await box.put(key, newData);
      print('✅ Updated $boxName[$key]');
      printEntry(boxName, key);
    } catch (e) {
      print('❌ Error updating: $e');
    }
  }

  /// 특정 엔트리 삭제 (디버그용)
  static Future<void> deleteEntry(String boxName, String key) async {
    try {
      final box = Hive.box<Map>(boxName);
      await box.delete(key);
      print('✅ Deleted $boxName[$key]');
    } catch (e) {
      print('❌ Error deleting: $e');
    }
  }

  /// 모든 데이터 삭제 (디버그용 - 주의!)
  static Future<void> clearAllData() async {
    try {
      await Hive.box<Map>('diary_entries').clear();
      await Hive.box<Map>('purchased_diaries').clear();
      print('✅ All Hive data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}
