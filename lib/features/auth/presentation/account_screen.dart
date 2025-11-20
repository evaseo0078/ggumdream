// lib/features/auth/presentation/diary_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/user_provider.dart';
import '../application/shop_provider.dart';
import '../../shop/domain/shop_item.dart';
import '../../../home/home_shell.dart';
import '../../diary/presentation/shop_detail_screen.dart';

class DiaryShopScreen extends ConsumerWidget {
  const DiaryShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);

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
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: const Text(
                "GGUM store",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Stencil',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAABCC5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Market",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        color: Colors.grey[300],
                        child: Text(
                          "${userState.coins}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: shopItems.length,
                itemBuilder: (context, index) {
                  return _buildShopItem(context, ref, shopItems[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, WidgetRef ref, ShopItem item) {
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
                      item.date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                      child: Icon(
                        Icons.image,
                        color: item.isSold ? Colors.grey[400] : Colors.grey,
                      ),
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
                              item.content,
                              maxLines: 2,
                              style: TextStyle(
                                decoration: item.isSold
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isSold ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "${item.price} coins ",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: item.isSold
                                    ? null
                                    : () {
                                        _confirmPurchase(context, ref, item);
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isSold
                                        ? Colors.grey
                                        : const Color(0xFFAABCC5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.isSold ? "Sold Out" : "Buy",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.isSold
                                          ? Colors.white
                                          : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmPurchase(BuildContext context, WidgetRef ref, ShopItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Purchase"),
          content: Text(
            "Do you really want to buy this dream for ${item.price} coins?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // [수정됨] item 객체 전달
                final success = ref
                    .read(userProvider.notifier)
                    .purchaseItem(item);
                if (success) {
                  ref.read(shopProvider.notifier).markAsSold(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Purchase Successful!")),
                  );
                  ref.read(homeTabProvider.notifier).state = 2;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Not enough coins!")),
                  );
                }
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
