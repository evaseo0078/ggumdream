import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shop/domain/shop_item.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import 'shop_detail_screen.dart';

class DiaryShopScreen extends ConsumerStatefulWidget {
  const DiaryShopScreen({super.key});

  @override
  ConsumerState<DiaryShopScreen> createState() => _DiaryShopScreenState();
}

class _DiaryShopScreenState extends ConsumerState<DiaryShopScreen> {
  bool _showMySales = false;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);

    final filteredItems = _showMySales
        ? shopItems.where((item) => item.ownerId == userState.userId).toList()
        : shopItems.where((item) => item.ownerId != userState.userId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFAABCC5),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: const Text(
                "GGUM store",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Stencil'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildTabButton("Market", !_showMySales),
                      const SizedBox(width: 10),
                      _buildTabButton("My Sales", _showMySales),
                    ],
                  ),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.star, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: Colors.grey[300],
                        child: Text(
                          "${userState.coins}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        _showMySales
                            ? "You are not selling any dreams."
                            : "No items in the market.",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildShopItem(context, ref, filteredItems[index], userState.userId);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMySales = (text == "My Sales");
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFAABCC5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.grey),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildShopItem(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
    String userId,
  ) {
    final isMine = item.ownerId == userId;
    final dateText = DateFormat('yyyy.MM.dd').format(item.date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShopDetailScreen(item: item)),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isSold ? Colors.grey[200] : Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Owner: ${item.ownerName}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : Icon(Icons.image, color: item.isSold ? Colors.grey[400] : Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            height: 40,
                            child: Text(
                              item.summary ?? "Summary hidden",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                decoration: item.isSold ? TextDecoration.lineThrough : null,
                                color: item.isSold ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (item.isSold)
                                const Text("Sold", style: TextStyle(color: Colors.grey))
                              else if (isMine)
                                const Text("Selling", style: TextStyle(color: Colors.orange)),
                              const SizedBox(width: 12),
                              WobblyPriceTag(price: item.price, isSold: item.isSold),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class WobblyPriceTag extends StatelessWidget {
  final int price;
  final bool isSold;

  const WobblyPriceTag({
    super.key,
    required this.price,
    required this.isSold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSold ? Colors.grey : const Color(0xFFAABCC5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        "$price GG",
        style: TextStyle(
          color: isSold ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
