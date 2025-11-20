// lib/features/shop/domain/shop_item.dart

class ShopItem {
  final String id;
  final String date;
  final String content;
  final int price;
  final String ownerName;
  final String? summary;
  final String? interpretation;
  final String? imageUrl;
  bool isSold;

  ShopItem({
    required this.id,
    required this.date,
    required this.content,
    required this.price,
    required this.ownerName,
    this.summary,
    this.interpretation,
    this.imageUrl,
    this.isSold = false,
  });
}
