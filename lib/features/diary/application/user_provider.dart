// lib/features/diary/application/user_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/domain/shop_item.dart';

class UserState {
  final String username; // Firestore의 nickname에 해당
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
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userDocSubscription;

  UserNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(UserState.initial()) {
    // 🔔 로그인 / 로그아웃 감시
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (!mounted) return;

      // 이전 유저 도큐먼트 리스너 정리
      _userDocSubscription?.cancel();
      _userDocSubscription = null;

      if (user != null) {
        _listenUserDoc(user.uid);
      } else {
        state = UserState.initial();
      }
    });
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// ✅ 현재 로그인 유저의 users/{uid} 문서를 실시간으로 listen
  void _listenUserDoc(String uid) {
    final docRef = _users.doc(uid);

    _userDocSubscription = docRef.snapshots().listen(
      (snapshot) async {
        if (!mounted) return;

        if (!snapshot.exists) {
          // 문서가 없으면 기본 정보 생성
          await docRef.set({
            'nickname': _auth.currentUser?.email ?? 'Dreamer',
            'email': _auth.currentUser?.email,
            'profileImageIndex': 1,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return;
        }

        final data = snapshot.data();
        if (data == null) return;

        // Firestore 상 coins / nickname 등 변경 → UserState 갱신
        state = UserState.fromFirestore(uid, data);
      },
      onError: (_) {
        // 에러 시에는 상태를 건드리지 않고 무시 (필요시 로그 추가 가능)
      },
    );
  }

  /// 수동 새로고침이 필요할 때 (지금 구조에서는 거의 필요 없음)
  Future<void> refresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _users.doc(uid).get();
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

  /// 🔹 이제 이 함수는 "로컬 잔액 충분한지 미리 체크" 용도로만 사용
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (state.coins < amount) return false;

    // 실제 코인 차감은 Cloud Functions(purchaseMarketItem)에서 처리
    // 여기서는 true/false만 리턴해서 구매 버튼 제어용으로 사용
    return true;
  }

  /// 테스트용/기타 용도로 남겨두지만,
  /// 실제 프로덕션에서는 Cloud Functions로 통일하는 것이 좋음.
  Future<void> earnCoins(int amount) async {
    if (amount <= 0) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final newBalance = state.coins + amount;
    await _users.doc(uid).set({'coins': newBalance}, SetOptions(merge: true));
    // 문서가 변경되면 snapshots().listen 이 알아서 state를 업데이트함.
  }

  // 아래 purchaseItem / recordSale / cancelSale / updateSalePrice 는
  // "클라이언트 내부 상태" 용도로만 계속 사용 (Firestore coins는 건드리지 않음)

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

  void recordSale(ShopItem item) {
    final newSalesHistory = [...state.salesHistory, item];
    state = state.copyWith(salesHistory: newSalesHistory);
    _updateUserData();
  }

  void cancelSale(String diaryId) {
    final newSalesHistory =
        state.salesHistory.where((item) => item.diaryId != diaryId).toList();
    state = state.copyWith(salesHistory: newSalesHistory);
    _updateUserData();
  }

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

    await _users.doc(uid).set({
      'nickname': state.username,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}

/// ✅ 현재 로그인한 유저 (본인) 상태
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

/// ✅ 임의의 uid에 대한 Firestore users/{uid} 문서를 실시간으로 구독
///    - 마켓에서 sellerUid → 최신 nickname 가져올 때 사용
final userByIdProvider =
    StreamProvider.family<UserState?, String>((ref, uid) {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection('users').doc(uid);

  return docRef.snapshots().map((snapshot) {
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserState.fromFirestore(uid, data);
  });
});
