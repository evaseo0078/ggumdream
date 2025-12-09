// lib/features/diary/application/user_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/domain/shop_item.dart';

class UserState {
  final String username;
  final String userId;
  final int coins;
  final List<ShopItem> purchaseHistory;
  final List<ShopItem> salesHistory;

  const UserState({
    required this.username,
    required this.userId,
    required this.coins,
    this.purchaseHistory = const [],
    this.salesHistory = const [],
  });

  factory UserState.initial() =>
      const UserState(username: 'Dreamer', userId: '', coins: 0);

  factory UserState.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserState(
      username: data['nickname'] as String? ??
          data['name'] as String? ??
          data['email'] as String? ??
          'Dreamer',
      userId: uid,
      coins: (data['coins'] is num) ? (data['coins'] as num).toInt() : 0,
      purchaseHistory: const [],
      salesHistory: const [],
    );
  }

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
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _authSubscription;

  UserNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(UserState.initial()) {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user != null) {
        _loadUser();
      } else {
        state = UserState.initial();
      }
    });
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ---------------------------------------------------------------------------
  // 유저 정보 로드 (문서 없으면 생성)
  // ---------------------------------------------------------------------------
  Future<void> _loadUser() async {
    if (!mounted) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _users.doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set(
        {
          'nickname': _auth.currentUser?.email ?? 'Dreamer',
          'email': _auth.currentUser?.email,
          'profileImageIndex': 1,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    final fresh = await docRef.get();
    if (fresh.exists && mounted) {
      state = UserState.fromFirestore(uid, fresh.data()!);
    }
  }

  Future<void> refresh() async => _loadUser();

  // ---------------------------------------------------------------------------
  // 코어 상태 업데이트 유틸
  // ---------------------------------------------------------------------------

  /// 코인 값을 절대값으로 세팅 (필요시 서버에서 읽어온 값 반영용)
  void setCoins(int coins) {
    state = state.copyWith(coins: coins);
  }

  /// 코인을 amount 만큼 로컬 상태에서만 차감 (Cloud Functions 성공 후 호출)
  void decreaseCoins(int amount) {
    if (amount <= 0) return;
    final newBalance = state.coins - amount;
    state = state.copyWith(coins: newBalance);
  }

  Future<void> setUser({
    required String username,
    required String userId,
    required int coins,
  }) async {
    state = state.copyWith(username: username, userId: userId, coins: coins);
    if (userId.isEmpty) return;

    await _users.doc(userId).set(
      {
        'nickname': username,
      },
      SetOptions(merge: true),
    );
  }

  /// 구매 전에 "잔액이 충분한지"만 체크 (실제 차감은 Cloud Functions 담당)
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (state.coins < amount) return false;
    return true;
  }

  /// 보상/수익 등으로 코인 추가 (이건 서버/클라 둘 다 업데이트)
  Future<void> earnCoins(int amount) async {
    if (amount <= 0) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final newBalance = state.coins + amount;
    await _users.doc(uid).set(
      {'coins': newBalance},
      SetOptions(merge: true),
    );
    state = state.copyWith(coins: newBalance, userId: uid);
  }

  // ---------------------------------------------------------------------------
  // 구매 / 판매 기록 (필요하면 사용)
  // ---------------------------------------------------------------------------

  // Purchase an item (로컬 기록용 – 현재 코인 차감은 Cloud Functions + decreaseCoins 로 처리)
  bool purchaseItem(ShopItem item) {
    if (state.coins < item.price) return false;

    final newPurchaseHistory = [...state.purchaseHistory, item];
    state = state.copyWith(
      coins: state.coins - item.price,
      purchaseHistory: newPurchaseHistory,
    );

    _updateUserData();
    return true;
  }

  // Record a sale
  void recordSale(ShopItem item) {
    final newSalesHistory = [...state.salesHistory, item];
    state = state.copyWith(salesHistory: newSalesHistory);
    _updateUserData();
  }

  // Cancel a sale
  void cancelSale(String diaryId) {
    final newSalesHistory =
        state.salesHistory.where((item) => item.diaryId != diaryId).toList();
    state = state.copyWith(salesHistory: newSalesHistory);
    _updateUserData();
  }

  // Update sale price
  void updateSalePrice(String diaryId, int newPrice) {
    final newSalesHistory = state.salesHistory.map((item) {
      if (item.diaryId == diaryId) {
        return item.copyWith(price: newPrice);
      }
      return item;
    }).toList();

    state = state.copyWith(salesHistory: newSalesHistory);
    _updateUserData();
  }

  Future<void> _updateUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _users.doc(uid).set(
      {
        'nickname': state.username,
        // coins 는 Cloud Functions / earnCoins 가 관리
      },
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
