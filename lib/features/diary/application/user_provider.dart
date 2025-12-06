import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/domain/shop_item.dart';

const int kDefaultCoins = 1000;

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

  factory UserState.initial() => const UserState(
        username: 'Dreamer',
        userId: '',
        coins: kDefaultCoins,
      );

  factory UserState.fromFirestore(String uid, Map<String, dynamic> data) {
    final coinsRaw = data['coins'];

    return UserState(
      username: data['nickname'] as String? ??
          data['name'] as String? ??
          data['email'] as String? ??
          'Dreamer',
      userId: uid,
      coins: (coinsRaw is num) ? coinsRaw.toInt() : kDefaultCoins,
      purchaseHistory: [], // TODO
      salesHistory: [], // TODO
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

  Future<void> _ensureUserDoc(String uid, {String? email}) async {
    final ref = _users.doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'nickname': email ?? 'Dreamer',
        'coins': kDefaultCoins,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = doc.data();
      if (data != null && !data.containsKey('coins')) {
        await ref.set({'coins': kDefaultCoins}, SetOptions(merge: true));
      }
    }
  }

  Future<void> _loadUser() async {
    if (!mounted) return;

    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    await _ensureUserDoc(uid, email: user?.email);

    final doc = await _users.doc(uid).get();
    if (doc.exists && mounted) {
      state = UserState.fromFirestore(uid, doc.data()!);
    }
  }

  Future<void> refresh() async => _loadUser();

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
        'coins': coins,
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> spendCoins(int amount) async {
    if (state.coins < amount) return false;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final newBalance = state.coins - amount;
    await _users.doc(uid).set({'coins': newBalance}, SetOptions(merge: true));
    state = state.copyWith(coins: newBalance, userId: uid);
    return true;
  }

  Future<void> earnCoins(int amount) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final newBalance = state.coins + amount;
    await _users.doc(uid).set({'coins': newBalance}, SetOptions(merge: true));
    state = state.copyWith(coins: newBalance, userId: uid);
  }

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
    final newSalesHistory = state.salesHistory
        .where((item) => item.diaryId != diaryId)
        .toList();
    state = state.copyWith(salesHistory: newSalesHistory);
    _updateUserData();
  }

  void updateSalePrice(String diaryId, int newPrice) {
    final newSalesHistory = state.salesHistory.map((item) {
      if (item.diaryId == diaryId) {
        return ShopItem(
          id: item.id,
          diaryId: item.diaryId,
          sellerUid: item.sellerUid,
          ownerName: item.ownerName,
          date: item.date,
          content: item.content,
          price: newPrice,
          summary: item.summary,
          interpretation: item.interpretation,
          imageUrl: item.imageUrl,
          buyerUid: item.buyerUid,
          isSold: item.isSold,
          createdAt: item.createdAt,
          purchasedAt: item.purchasedAt,
        );
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
      'coins': state.coins,
    }, SetOptions(merge: true));
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
