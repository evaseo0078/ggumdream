// lib/features/shop/domain/shop_item.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ShopItem {
  final String id;
  final String diaryId;
  final String sellerUid;
  final String ownerName;
  final DateTime date;
  final String content;
  final int price;
  final String? summary;
  final String? interpretation;
  final String? imageUrl;
  final String? buyerUid;
  final bool isSold;
  final DateTime? createdAt;
  final DateTime? purchasedAt;

  const ShopItem({
    required this.id,
    required this.diaryId,
    required this.sellerUid,
    required this.ownerName,
    required this.date,
    required this.content,
    required this.price,
    this.summary,
    this.interpretation,
    this.imageUrl,
    this.buyerUid,
    this.isSold = false,
    this.createdAt,
    this.purchasedAt,
  });

  ShopItem copyWith({
    String? id,
    String? diaryId,
    String? sellerUid,
    String? ownerName,
    DateTime? date,
    String? content,
    int? price,
    String? summary,
    String? interpretation,
    String? imageUrl,
    String? buyerUid,
    bool? isSold,
    DateTime? createdAt,
    DateTime? purchasedAt,
  }) {
    return ShopItem(
      id: id ?? this.id,
      diaryId: diaryId ?? this.diaryId,
      sellerUid: sellerUid ?? this.sellerUid,
      ownerName: ownerName ?? this.ownerName,
      date: date ?? this.date,
      content: content ?? this.content,
      price: price ?? this.price,
      summary: summary ?? this.summary,
      interpretation: interpretation ?? this.interpretation,
      imageUrl: imageUrl ?? this.imageUrl,
      buyerUid: buyerUid ?? this.buyerUid,
      isSold: isSold ?? this.isSold,
      createdAt: createdAt ?? this.createdAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'diaryId': diaryId,
      'sellerUid': sellerUid,
      'ownerName': ownerName,
      'date': Timestamp.fromDate(date),
      'content': content,
      'price': price,
      'summary': summary,
      'interpretation': interpretation,
      'imageUrl': imageUrl,
      'buyerUid': buyerUid,
      'isSold': isSold,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (purchasedAt != null) 'purchasedAt': Timestamp.fromDate(purchasedAt!),
    };
  }

  factory ShopItem.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return ShopItem(
      id: id,
      diaryId: data['diaryId'] as String? ?? '',
      sellerUid: data['sellerUid'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      date: parseDate(data['date']),
      content: data['content'] as String? ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toInt() : 0,
      summary: data['summary'] as String?,
      interpretation: data['interpretation'] as String?,
      imageUrl: data['imageUrl'] as String?,
      buyerUid: data['buyerUid'] as String?,
      isSold: data['isSold'] as bool? ?? false,
      createdAt: data['createdAt'] != null ? parseDate(data['createdAt']) : null,
      purchasedAt:
          data['purchasedAt'] != null ? parseDate(data['purchasedAt']) : null,
    );
  }
}
