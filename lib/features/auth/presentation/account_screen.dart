// lib/features/auth/presentation/account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../diary/application/user_provider.dart';
import '../../diary/application/shop_provider.dart';
import '../../diary/presentation/shop_detail_screen.dart';
import '../../shop/domain/shop_item.dart';
import '../../diary/presentation/stats_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);
    
    // Debug info
    print('DEBUG - Current user ID: ${userState.userId}');
    print('DEBUG - Total shop items: ${shopItems.length}');
    for (var item in shopItems) {
      print('DEBUG - Item: sellerUid=${item.sellerUid}, buyerUid=${item.buyerUid}, isSold=${item.isSold}, content=${item.content.substring(0, 20)}...');
    }
    
    // Filter current user's selling items (실제 상점에서 판매 중인 아이템들)
    final mySellingItems = shopItems.where(
      (item) => item.sellerUid == userState.userId && !item.isSold
    ).toList();
    
    // Filter sold items (판매 완료된 아이템들)
    final mySoldItems = shopItems.where(
      (item) => item.sellerUid == userState.userId && item.isSold
    ).toList();
    
    // Filter purchased items (구매한 아이템들)
    final myPurchasedItems = shopItems.where(
      (item) => item.buyerUid == userState.userId && item.isSold
    ).toList();
    
    print('DEBUG - My selling items: ${mySellingItems.length}');
    print('DEBUG - My sold items: ${mySoldItems.length}');
    print('DEBUG - My purchased items: ${myPurchasedItems.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Account Page", style: TextStyle(color: Colors.black26, fontSize: 16)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. 유저네임
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userState.username,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // 2. 프로필 정보
            Row(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFFAABCC5),
                  child: Icon(Icons.person_outline, size: 50, color: Colors.black),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40, child: Text("Coins", style: TextStyle(fontSize: 12))),
                          Expanded(child: Container(height: 24, color: Colors.grey[300], padding: const EdgeInsets.only(left:8), child: Text("${userState.coins}", style: const TextStyle(fontWeight: FontWeight.bold))))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 40, child: Text("ID", style: TextStyle(fontSize: 12))),
                          Expanded(child: Container(height: 24, color: Colors.grey[300], padding: const EdgeInsets.only(left:8), child: Text(userState.userId)))
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: SizedBox(height: 30, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAABCC5), elevation: 0), child: const Text("Edit Profile", style: TextStyle(color: Colors.black54, fontSize: 12))))),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 24),

            // ✨ [추가됨] 통계 분석 버튼 (Purchase History 바로 위에 배치 추천)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatsScreen()),
                  );
                },
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                label: const Text("Analyze Sleep & Dreams", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // 3. Purchase History (실제 구매한 아이템들 + UserState history)
            const Align(alignment: Alignment.centerLeft, child: Text("Purchase History", style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
              child: (myPurchasedItems.isEmpty && userState.purchaseHistory.isEmpty)
                ? const Text("No items purchased.", style: TextStyle(color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (myPurchasedItems.isNotEmpty) ...[
                        const Text("From Shop:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ...myPurchasedItems.map((item) => _buildPurchaseItem(context, item)).toList(),
                      ],
                      if (userState.purchaseHistory.isNotEmpty) ...[
                        const Text("Purchase History:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ...userState.purchaseHistory.map((item) => _buildPurchaseItem(context, item)).toList(),
                      ],
                    ],
                  ),
            ),

            const SizedBox(height: 24),

            // 4. Currently Selling (현재 판매 중인 아이템들 + UserState sales)
            const Align(alignment: Alignment.centerLeft, child: Text("Currently Selling", style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
              child: (mySellingItems.isEmpty && userState.salesHistory.isEmpty)
                ? const Text("No items for sale.", style: TextStyle(color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mySellingItems.isNotEmpty) ...[
                        const Text("In Shop:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ...mySellingItems.map((item) => _buildSellingItem(context, item)).toList(),
                      ],
                      if (userState.salesHistory.isNotEmpty) ...[
                        const Text("Sales History:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ...userState.salesHistory.map((item) => _buildSellingItem(context, item)).toList(),
                      ],
                    ],
                  ),
            ),

            const SizedBox(height: 24),

            // 5. Sold Items (판매 완료된 아이템들)
            const Align(alignment: Alignment.centerLeft, child: Text("Sold Items", style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
              child: mySoldItems.isEmpty
                ? const Text("No items sold yet.", style: TextStyle(color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: mySoldItems.map((item) => _buildSoldItem(context, item)).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItem(BuildContext context, ShopItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(
              item: item,
              isPurchased: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.summary ?? item.content,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "by ${item.ownerName}",
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              "${item.price}c",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellingItem(BuildContext context, ShopItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(
              item: item,
              isPurchased: false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.sell, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.summary ?? item.content,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "For Sale",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${item.price}c",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldItem(BuildContext context, ShopItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(
              item: item,
              isPurchased: false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.summary ?? item.content,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.buyerUid != null ? "Sold to buyer" : "Sold",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${item.price}c",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}