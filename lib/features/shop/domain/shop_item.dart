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

  /// Firestore에 저장할 때: status / isSold 둘 다 기록
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
      'status': isSold ? 'sold' : 'listed',
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (purchasedAt != null)
        'purchasedAt': Timestamp.fromDate(purchasedAt!),
    };
  }

  factory ShopItem.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      // null이면 지금 시각으로 fallback
      return DateTime.now();
    }

    bool parseIsSold(Map<String, dynamic> d) {
      // 1) isSold 필드가 있으면 우선
      final dynamic raw = d['isSold'];
      if (raw is bool) return raw;

      // 2) status 필드(string) 있는 경우
      final status = d['status'];
      if (status is String) {
        // listed 이외 값(sold, cancelled 등)은 모두 팔린 것으로 간주
        return status != 'listed';
      }

      // 3) 둘 다 없으면 기본값 false
      return false;
    }

    // purchasedAt: 없고 soldAt만 있는 경우도 함께 처리
    final purchasedAtRaw = data['purchasedAt'] ?? data['soldAt'];

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
      isSold: parseIsSold(data),
      createdAt:
          data['createdAt'] != null ? parseDate(data['createdAt']) : null,
      purchasedAt:
          purchasedAtRaw != null ? parseDate(purchasedAtRaw) : null,
    );
  }
}
