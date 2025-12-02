import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../home/home_shell.dart';
import '../../shop/domain/shop_item.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../data/purchase_repository.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';

class ShopDetailScreen extends ConsumerWidget {
  final ShopItem item;
  final bool isPurchased;

  const ShopDetailScreen({super.key, required this.item, this.isPurchased = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateText = DateFormat('yyyy.MM.dd').format(item.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          "$dateText (by ${item.ownerName})",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Stencil',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WobblyContainer(
                  backgroundColor: Colors.grey.shade300,
                  borderColor: Colors.black12,
                  borderRadius: 8,
                  constraints: BoxConstraints.tight(const Size(140, 140)),
                  child: Stack(
                    children: [
                      item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
                      if (!isPurchased)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                                child: const Center(
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildResultBox(
                        "Summary",
                        isPurchased 
                            ? (item.summary ?? "No summary available")
                            : "🔒 Purchase to view summary",
                        isBlurred: !isPurchased,
                      ),
                      const SizedBox(height: 10),
                      _buildResultBox(
                        "Interpretation",
                        isPurchased 
                            ? (item.interpretation ?? "No interpretation available")
                            : "🔒 Purchase to view interpretation",
                        isBlurred: !isPurchased,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Dream Content",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            WobblyContainer(
              backgroundColor: Colors.white,
              borderColor: Colors.black12,
              borderRadius: 8,
              padding: const EdgeInsets.all(16),
              constraints:
                  const BoxConstraints(minWidth: double.infinity, minHeight: 150),
              child: Stack(
                children: [
                  Text(
                    isPurchased ? item.content : item.content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (!isPurchased)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.black.withOpacity(0.1),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: Colors.black54,
                                    size: 30,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Purchase to read the dream",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (!isPurchased && !item.isSold)
              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: WobblyContainer(
                    backgroundColor: const Color(0xFFAABCC5),
                    borderColor: Colors.black,
                    borderRadius: 25,
                    child: ElevatedButton(
                      onPressed: () {
                        _confirmPurchase(context, ref);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        "Buy for ${item.price} Coins",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String content, {bool isBlurred = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        WobblyContainer(
          backgroundColor: Colors.white,
          borderColor: Colors.black12,
          borderRadius: 4,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: double.infinity),
          child: Stack(
            children: [
              Text(
                content,
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (isBlurred)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.black.withOpacity(0.05),
                        child: const Center(
                          child: Icon(
                            Icons.lock_outline,
                            color: Colors.black38,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmPurchase(BuildContext context, WidgetRef ref) {
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
              onPressed: () async {
                Navigator.pop(dialogContext);
                final userState = ref.read(userProvider);
                if (userState.userId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please sign in first.")),
                  );
                  return;
                }

                final spent = await ref
                    .read(userProvider.notifier)
                    .spendCoins(item.price);
                if (!spent) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Not enough coins!")),
                    );
                  }
                  return;
                }

                await ref.read(purchaseRepositoryProvider).recordPurchase(item);
                await ref
                    .read(shopProvider.notifier)
                    .markAsSold(item.id, buyerId: userState.userId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Purchase Successful!")),
                  );
                  Navigator.pop(context);
                  ref.read(homeTabProvider.notifier).state = 2;
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
