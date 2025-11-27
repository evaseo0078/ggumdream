// lib/features/diary/application/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/domain/shop_item.dart';

/// 앱에서 사용하는 유저 상태
class UserState {
  /// 화면에 보여줄 이름(닉네임 역할)
  final String username;

  /// 내부적으로 쓸 아이디 (나중에 Firebase uid / email 매핑해서 사용 가능)
  final String userId;

  /// 보유 코인
  final int coins;

  /// 내가 구매한 아이템 기록
  final List<ShopItem> purchaseHistory;

  /// 내가 판매 등록한 아이템 기록
  final List<ShopItem> salesHistory;

  const UserState({
    required this.username,
    required this.userId,
    required this.coins,
    required this.purchaseHistory,
    required this.salesHistory,
  });

  /// 초기 기본값 (게스트 느낌)
  factory UserState.initial() => const UserState(
        username: 'Dreamer',
        userId: 'user123',
        coins: 1000,
        purchaseHistory: [],
        salesHistory: [],
      );

  UserState copyWith({
    String? username,
    String? userId,
    int? coins,
    List<ShopItem>? purchaseHistory,
    List<ShopItem>? salesHistory,
  }) {
    return UserState(
      username: username ?? this.username,
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      salesHistory: salesHistory ?? this.salesHistory,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState.initial());

  /// 아이템 구매 (코인 차감 + 구매 내역 추가)
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

  /// 판매 등록
  void recordSale(ShopItem item) {
    state = state.copyWith(
      salesHistory: [...state.salesHistory, item],
    );
  }

  /// 판매 취소
  void cancelSale(String content) {
    state = state.copyWith(
      salesHistory: state.salesHistory
          .where((item) => item.content != content)
          .toList(),
    );
  }

  /// 판매 가격 수정
  void updateSalePrice(String content, int newPrice) {
    state = state.copyWith(
      salesHistory: [
        for (final item in state.salesHistory)
          if (item.content == content)
            ShopItem(
              id: item.id,
              date: item.date,
              content: item.content,
              price: newPrice, // 🔁 가격만 변경
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

  /// 코인 지급
  void earnCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }

  /// 🔹 로그인한 유저 정보로 상태를 교체할 때 사용 (Firebase에서 받아온 값 넣어주기)
  void setUser({
    required String username,
    required String userId,
    required int coins,
  }) {
    state = state.copyWith(
      username: username,
      userId: userId,
      coins: coins,
    );
  }
}

/// 전역 userProvider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
