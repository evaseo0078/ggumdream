import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/user_provider.dart';
import '../application/shop_provider.dart';
import '../../../home/home_shell.dart';
import 'shop_detail_screen.dart'; 
import '../../shop/domain/shop_item.dart'; 

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
        ? shopItems.where((item) => item.ownerName == userState.username).toList()
        : shopItems.where((item) => item.ownerName != userState.username).toList();

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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: const Text(
                "GGUM store",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Stencil'),
              ),
            ),

            // 2. 탭 및 정보 바
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
                        child: Text("${userState.coins}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
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
                        return _buildShopItem(context, ref, filteredItems[index]);
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

  Widget _buildShopItem(BuildContext context, WidgetRef ref, ShopItem item) {
    final isMine = _showMySales; 

    return GestureDetector(
      // ⚡ [핵심 수정] 탭(Click) 이벤트 제어
      onTap: () {
        if (isMine) {
          // 1. 내 물건이면 -> 상세 페이지 이동 (자유롭게 열람)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ShopDetailScreen(item: item)),
          );
        } else if (item.isSold) {
          // 2. 이미 구매한 물건이면 -> 상세 페이지 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ShopDetailScreen(item: item)),
          );
        } else {
          // 3. ✨ 안 샀으면 -> "구매하세요" 알림 팝업
          _showLockedAlert(context, ref, item);
        }
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
                    Text(item.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("Owner: ${item.ownerName}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      color: Colors.grey[300],
                      child: item.imageUrl != null
                          // 구매 전에는 블러 처리하거나 아이콘만 보여줄 수도 있음 (현재는 아이콘/이미지 유지)
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
                            // 구매 전에는 내용이 궁금하게 Summary만 보여줌
                            child: Text(
                              item.summary ?? "Secret Content 🔒", 
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                decoration: item.isSold ? TextDecoration.lineThrough : null,
                                color: item.isSold ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${item.price} coins ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                              const SizedBox(width: 8),
                              
                              if (isMine) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.isSold ? "Sold" : "My Item",
                                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ] else ...[
                                InkWell(
                                  onTap: item.isSold 
                                    ? null 
                                    : () {
                                        _confirmPurchase(context, ref, item);
                                      },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: item.isSold ? Colors.grey : const Color(0xFFAABCC5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.isSold ? "Sold Out" : "Buy",
                                      style: TextStyle(fontSize: 12, color: item.isSold ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ⚡ [추가됨] 잠김 알림 다이얼로그
  void _showLockedAlert(BuildContext context, WidgetRef ref, ShopItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.grey),
            SizedBox(width: 10),
            Text("Locked Content"),
          ],
        ),
        content: const Text("You need to buy this dream to view the full details."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // 닫고
              _confirmPurchase(context, ref, item); // 바로 구매창 띄우기
            },
            child: const Text("Buy Now"),
          ),
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
          content: Text("Do you really want to buy this dream for ${item.price} coins?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("No")),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final success = ref.read(userProvider.notifier).purchaseItem(item);
                if (success) {
                  ref.read(shopProvider.notifier).markAsSold(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Successful!")));
                  ref.read(homeTabProvider.notifier).state = 2; // 프로필 이동
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough coins!")));
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