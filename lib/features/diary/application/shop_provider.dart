import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/data/market_repository.dart';
import '../../shop/domain/shop_item.dart';
import '../domain/diary_entry.dart';

final marketRepositoryProvider = Provider<MarketRepository>(
  (ref) => MarketRepository(),
);

final shopProvider = StateNotifierProvider<ShopNotifier, List<ShopItem>>((ref) {
  final repo = ref.watch(marketRepositoryProvider);
  return ShopNotifier(repo);
});

class ShopNotifier extends StateNotifier<List<ShopItem>> {
  final MarketRepository _repo;
  StreamSubscription<List<ShopItem>>? _subscription;

  ShopNotifier(this._repo) : super([]) {
    _subscription = _repo.watchMarketItems().listen(
          (items) => state = items,
          onError: (_) => state = [],
        );
  }

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

  Future<void> markAsSold(String itemId, {String? buyerId}) async {
    await _repo.markAsSold(itemId, buyerId: buyerId);
  }

  Future<void> cancelListing(String diaryId) async {
    await _repo.deleteListingByDiary(diaryId);
  }

  Future<void> updatePrice(String itemId, int newPrice) async {
    await _repo.updatePrice(itemId, newPrice);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
