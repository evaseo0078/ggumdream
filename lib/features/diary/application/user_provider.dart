import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final String username;
  final String userId;
  final int coins;

  const UserState({
    required this.username,
    required this.userId,
    required this.coins,
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
    );
  }

  UserState copyWith({
    String? username,
    String? userId,
    int? coins,
  }) {
    return UserState(
      username: username ?? this.username,
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(UserState.initial()) {
    _loadUser();
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _users.doc(uid).get();
    if (doc.exists) {
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
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
