//lib/features/auth/application/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shop/domain/shop_item.dart';

class UserState {
  final String username;
  final String userId;
  final int coins;
  final List<ShopItem> purchaseHistory;
  final List<ShopItem> salesHistory;

  UserState({
    required this.username,
    required this.userId,
    required this.coins,
    required this.purchaseHistory,
    required this.salesHistory,
  });

  UserState copyWith({
    String? username,
    int? coins,
    List<ShopItem>? purchaseHistory,
    List<ShopItem>? salesHistory,
  }) {
    return UserState(
      username: username ?? this.username,
      userId: userId,
      coins: coins ?? this.coins,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      salesHistory: salesHistory ?? this.salesHistory,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier()
    : super(
        UserState(
          username: "Dreamer",
          userId: "user123",
          coins: 1000,
          purchaseHistory: [],
          salesHistory: [],
        ),
      );

  bool purchaseItem(ShopItem item) {
    if (state.coins >= item.price) {
      state = state.copyWith(
        coins: state.coins - item.price,
        purchaseHistory: [...state.purchaseHistory, item],
      );
      return true;
    }
    return false;
  }

  void recordSale(ShopItem item) {
    state = state.copyWith(salesHistory: [...state.salesHistory, item]);
  }

  // ⚡ [추가됨] 판매 취소 시 내역에서 삭제
  void cancelSale(String content) {
    state = state.copyWith(
      salesHistory: state.salesHistory
          .where((item) => item.content != content)
          .toList(),
    );
  }

  void updateSalePrice(String content, int newPrice) {
    state = state.copyWith(
      salesHistory: [
        for (final item in state.salesHistory)
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
      ],
    );
  }

  void earnCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
