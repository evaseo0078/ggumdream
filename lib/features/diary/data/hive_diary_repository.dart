//lib/features/diary/data/hive_diary_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final hiveDiaryRepositoryProvider = Provider<HiveDiaryRepository>(
  (ref) => HiveDiaryRepository(),
);

class HiveDiaryRepository {
  static const _boxName = 'diary_entries';

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> saveEntry(Map<String, dynamic> entry) async {
    final id = entry['id'] as String;
    await _box.put(id, entry);
  }

  Map<String, dynamic>? getEntryById(String id) {
    final map = _box.get(id);
    if (map == null) return null;
    return Map<String, dynamic>.from(map.cast<String, dynamic>());
  }

  List<Map<String, dynamic>> getAllEntriesSorted() {
    final list = _box.values
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList();
    list.sort((a, b) {
      final da = a['date'] is DateTime
          ? a['date'] as DateTime
          : DateTime.tryParse(a['date'].toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
      final db = b['date'] is DateTime
          ? b['date'] as DateTime
          : DateTime.tryParse(b['date'].toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return list;
  }

  Future<void> deleteEntry(String id) async => await _box.delete(id);
}
