// lib/features/auth/application/shop_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shop/domain/shop_item.dart';

class ShopNotifier extends StateNotifier<List<ShopItem>> {
  ShopNotifier() : super([]) {
    // 초기 더미 데이터
    state = [
      ShopItem(
        id: '1',
        date: '2006.12.09',
        content: "I want to fly to the moon.",
        price: 100,
        ownerName: "MoonWalker",
      ),
      ShopItem(
        id: '2',
        date: '2018.11.08',
        content: "Because i am happy",
        price: 50,
        ownerName: "HappyGuy",
      ),
    ];
  }

  void markAsSold(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          ShopItem(
            id: item.id,
            date: item.date,
            content: item.content,
            price: item.price,
            ownerName: item.ownerName,
            isSold: true,
          )
        else
          item,
    ];
  }

  // 내 일기를 상점에 등록하는 함수 (NEW)
  void addShopItem({
    required String date,
    required String content,
    required String ownerName,
    required int price,
  }) {
    final newItem = ShopItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 유니크 ID 생성
      date: date,
      content: content,
      price: price,
      ownerName: ownerName,
    );
    // 최신순으로 앞에 추가
    state = [newItem, ...state];
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, List<ShopItem>>((ref) {
  return ShopNotifier();
});
