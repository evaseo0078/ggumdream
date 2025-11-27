import 'package:cloud_firestore/cloud_firestore.dart';

import '../../diary/domain/diary_entry.dart';
import '../domain/shop_item.dart';

class MarketRepository {
  final FirebaseFirestore _firestore;

  MarketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('market_items');

  Stream<List<ShopItem>> watchMarketItems() {
    return _items
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopItem.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<ShopItem> createListing({
    required DiaryEntry diary,
    required String ownerId,
    required String ownerName,
    required int price,
  }) async {
    final doc = _items.doc();
    final item = ShopItem(
      id: doc.id,
      diaryId: diary.id,
      ownerId: ownerId,
      ownerName: ownerName,
      date: diary.date,
      content: diary.content,
      price: price,
      summary: diary.summary,
      interpretation: diary.interpretation,
      imageUrl: diary.imageUrl,
      isSold: false,
      createdAt: DateTime.now(),
    );

    await doc.set(item.toFirestore());
    return item;
  }

  Future<void> updatePrice(String itemId, int newPrice) async {
    await _items.doc(itemId).update({'price': newPrice});
  }

  Future<void> markAsSold(String itemId, {String? buyerId}) async {
    await _items
        .doc(itemId)
        .update({'isSold': true, if (buyerId != null) 'buyerId': buyerId});
  }

  Future<void> deleteListingByDiary(String diaryId) async {
    final existing =
        await _items.where('diaryId', isEqualTo: diaryId).limit(1).get();
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.delete();
    }
  }
}
