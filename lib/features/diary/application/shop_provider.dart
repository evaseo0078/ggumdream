// lib/features/diary/application/shop_provider.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shop/data/market_repository.dart';
import '../../shop/domain/shop_item.dart';
import '../domain/diary_entry.dart';

/// 마켓 리포지토리 프로바이더
final marketRepositoryProvider = Provider<MarketRepository>(
  (ref) => MarketRepository(),
);

/// 상점(꿈 마켓) 상태 프로바이더
final shopProvider = StateNotifierProvider<ShopNotifier, List<ShopItem>>((ref) {
  final repo = ref.watch(marketRepositoryProvider);
  return ShopNotifier(repo);
});

class ShopNotifier extends StateNotifier<List<ShopItem>> {
  final MarketRepository _repo;
  StreamSubscription<List<ShopItem>>? _subscription;

  ShopNotifier(this._repo) : super([]) {
    // 마켓 아이템 실시간 구독
    _subscription = _repo.watchMarketItems().listen(
          (items) => state = items,
          onError: (_) => state = [],
        );
  }

  /// 일기를 마켓에 등록
  Future<ShopItem> createListing({
    required DiaryEntry diary,
    required String ownerId,
    required String ownerName,
    required int price,
  }) {
    return _repo.createListing(
      diary: diary,
      ownerId: ownerId,
      ownerName: ownerName,
      price: price,
    );
  }

  /// 아이템을 구매 완료 상태로 표시
  /// - buyerId가 넘어오면 그 값 사용
  /// - 없으면 현재 로그인한 사용자의 uid 사용
  Future<void> markAsSold(String itemId, {String? buyerId}) async {
    // 1) buyerId 우선 사용, 없으면 현재 로그인 유저
    final uid = buyerId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user for purchase.');
    }

    // 2) 실제 Firestore 업데이트는 리포지토리에 위임
    await _repo.markAsSold(itemId, buyerId: uid);
  }

  /// 마켓에서 등록 취소 (원래 주인만 가능)
  Future<void> cancelListing(String diaryId) async {
    await _repo.deleteListingByDiary(diaryId);
  }

  /// 가격 수정
  Future<void> updatePrice(String itemId, int newPrice) async {
    await _repo.updatePrice(itemId, newPrice);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
