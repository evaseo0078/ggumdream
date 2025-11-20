// lib/features/diary/presentation/diary_shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/user_provider.dart';
import '../application/shop_provider.dart';
import '../../../home/home_shell.dart';
import 'shop_detail_screen.dart';
import '../../shop/domain/shop_item.dart';

// ⚡ 탭 전환 상태 관리를 위해 Stateful로 변경
class DiaryShopScreen extends ConsumerStatefulWidget {
  const DiaryShopScreen({super.key});

  @override
  ConsumerState<DiaryShopScreen> createState() => _DiaryShopScreenState();
}

class _DiaryShopScreenState extends ConsumerState<DiaryShopScreen> {
  // false: Market(남의 것), true: My Sales(내 것)
  bool _showMySales = false;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);

    // ⚡ 필터링 로직
    // 1. Market: 주인이 내가 아닌 것들
    // 2. My Sales: 주인이 나인 것들
    final filteredItems = _showMySales
        ? shopItems
              .where((item) => item.ownerName == userState.username)
              .toList()
        : shopItems
              .where((item) => item.ownerName != userState.username)
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 헤더
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

            // 2. 탭 및 정보 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ⚡ 탭 전환 버튼 (Market vs My Sales)
                  Row(
                    children: [
                      _buildTabButton("Market", !_showMySales),
                      const SizedBox(width: 10),
                      _buildTabButton("My Sales", _showMySales),
                    ],
                  ),

                  // 내 코인 정보
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

            // 3. 리스트 아이템
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
                        return _buildShopItem(
                          context,
                          ref,
                          filteredItems[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 탭 버튼 위젯
  Widget _buildTabButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 텍스트에 따라 모드 변경
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

  Widget _buildShopItem(BuildContext context, WidgetRef ref, ShopItem item) {
    // 내가 파는 물건인지 확인
    final isMine = _showMySales;

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
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : Icon(
                              Icons.image,
                              color: item.isSold
                                  ? Colors.grey[400]
                                  : Colors.grey,
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
                              item.summary ?? item.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                decoration: item.isSold
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isSold ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.w500,
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

                              // ⚡ 버튼 로직 분기
                              if (isMine) ...[
                                // 내 물건일 때: "Selling" (클릭 불가 또는 관리 기능)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.isSold ? "Sold" : "My Item",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // 남의 물건일 때: "Buy" 버튼
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
                final success = ref
                    .read(userProvider.notifier)
                    .purchaseItem(item);
                if (success) {
                  ref.read(shopProvider.notifier).markAsSold(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Purchase Successful!")),
                  );
                  ref.read(homeTabProvider.notifier).state = 2; // 프로필 이동
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
