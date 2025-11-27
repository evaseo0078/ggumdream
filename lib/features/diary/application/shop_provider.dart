// lib/features/diary/application/shop_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shop/domain/shop_item.dart';
import 'user_provider.dart';

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
        imageUrl: "https://picsum.photos/seed/moon/300/300",
        summary: "A dream about flying to the moon.",
        interpretation: "You have high ambitions.",
      ),
      ShopItem(
        id: '2',
        date: '2018.11.08',
        content: "Because i am happy",
        price: 50,
        ownerName: "HappyGuy",
        imageUrl: "https://picsum.photos/seed/happy/300/300",
        summary: "Feeling of joy.",
        interpretation: "Good mental health.",
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
            summary: item.summary,
            interpretation: item.interpretation,
            imageUrl: item.imageUrl,
            isSold: true,
          )
        else
          item,
    ];
  }

  void addShopItem({
    required String date,
    required String content,
    required String ownerName,
    required int price,
    String? summary,
    String? interpretation,
    String? imageUrl,
  }) {
    final newItem = ShopItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      content: content,
      price: price,
      ownerName: ownerName,
      summary: summary,
      interpretation: interpretation,
      imageUrl: imageUrl,
    );
    state = [newItem, ...state];
  }

  void addItem(ShopItem item) {
    state = [item, ...state];
  }

  // ⚡ [추가됨] 내용을 기준으로 상점 목록에서 삭제 (판매 취소용)
  void removeItemByContent(String content) {
    state = state.where((item) => item.content != content).toList();
  }

  void updatePrice(String content, int newPrice) {
    state = [
      for (final item in state)
        if (item.content == content)
          ShopItem(
            id: item.id,
            date: item.date,
            content: item.content,
            price: newPrice, // 가격 변경
            ownerName: item.ownerName,
            summary: item.summary,
            interpretation: item.interpretation,
            imageUrl: item.imageUrl,
            isSold: item.isSold,
          )
        else
          item,
    ];
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, List<ShopItem>>((ref) {
  return ShopNotifier();
});
