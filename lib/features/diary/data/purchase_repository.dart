// lib/features/diary/data/purchase_repository.dart (경로는 프로젝트 구조에 맞게 사용)

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

  /// 🔹 구매 기록 쓰기 (클라이언트에서는 더 이상 Firestore에 직접 쓰지 않음)
  ///
  /// Firestore 규칙에서:
  ///   match /users/{userId}/purchases/{purchaseId} {
  ///     allow read:  if request.auth != null && request.auth.uid == userId;
  ///     allow write: if false; // 서버 전용
  ///   }
  /// 로 막혀 있기 때문에,
  /// purchases 컬렉션에 대한 실제 생성/수정은
  /// Cloud Functions(서버)에서 처리해야 한다.
  ///
  /// 클라이언트에서는 이 메서드를 호출하지 않거나,
  /// 필요하다면 UI용 로컬 상태만 갱신하는 용도로 활용한다.
  Future<void> recordPurchase(ShopItem item) async {
    // ⚠️ Firestore에 쓰지 않고, 서버에서 기록하도록 위임.
    // 필요하다면 여기서 로컬 상태/캐시 갱신 로직만 넣어 사용할 수 있음.
    throw UnimplementedError(
      'recordPurchase는 클라이언트에서 직접 purchases 컬렉션에 쓰지 않습니다. '
      'Cloud Functions에서 구매 내역을 기록하도록 구현해야 합니다.',
    );
  }

  /// 🔹 구매 내역 조회 (읽기 전용)
  Future<List<ShopItem>> fetchPurchases() async {
    final uid = _requireUid();
    final snapshot =
        await _purchases(uid).orderBy('purchasedAt', descending: true).get();

    return snapshot.docs
        .map((doc) => ShopItem.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
