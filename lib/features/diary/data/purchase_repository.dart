import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shop/domain/shop_item.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepository(),
);

class PurchaseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PurchaseRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _purchases(String uid) {
    return _firestore.collection('users').doc(uid).collection('purchases');
  }

  Future<void> recordPurchase(ShopItem item) async {
    final uid = _requireUid();
    final purchased = item.copyWith(purchasedAt: DateTime.now());
    await _purchases(uid).doc(item.id).set(purchased.toFirestore());
  }

  Future<List<ShopItem>> fetchPurchases() async {
    final uid = _requireUid();
    final snapshot =
        await _purchases(uid).orderBy('purchasedAt', descending: true).get();

    return snapshot.docs
        .map((doc) => ShopItem.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
