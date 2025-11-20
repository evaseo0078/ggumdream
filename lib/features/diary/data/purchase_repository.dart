//lib/features/diary/data/purchase_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepository(),
);

class PurchaseRepository {
  static const _boxName = 'purchased_diaries';

  Box<Map> get _box => Hive.box<Map>(_boxName);

  // 구매 내역 저장
  Future<void> addPurchase(Map<String, dynamic> diary) async {
    final id = diary['id'] as String;
    await _box.put(id, diary);
  }

  // 구매한 일기 목록 가져오기 (최신순)
  List<Map<String, dynamic>> getPurchasedDiaries() {
    final list = _box.values
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList();

    // 날짜 기준으로 정렬
    list.sort((a, b) {
      final da = DateTime.tryParse(a['date'].toString()) ?? DateTime.now();
      final db = DateTime.tryParse(b['date'].toString()) ?? DateTime.now();
      return db.compareTo(da); // 최신순
    });

    return list;
  }

  // 특정 일기가 구매되었는지 확인
  bool isPurchased(String id) {
    return _box.containsKey(id);
  }
}
