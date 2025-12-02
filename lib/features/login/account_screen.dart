// lib/features/login/account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import 'auth_repository.dart';
import '../diary/application/user_provider.dart'; // 코인/닉네임 상태
import '../diary/application/shop_provider.dart';
import '../shop/domain/shop_item.dart';
import '../diary/presentation/shop_detail_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebase 현재 유저
    final authRepo = ref.watch(authRepositoryProvider);
    final firebaseUser = authRepo.currentUser;

    // 앱 내부 유저 상태 (닉네임, 코인 등)
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);
    
    // Filter current user's items
    final mySellingItems = shopItems.where(
      (item) => item.sellerUid == userState.userId && !item.isSold
    ).toList();
    
    final mySoldItems = shopItems.where(
      (item) => item.sellerUid == userState.userId && item.isSold
    ).toList();
    
    final myPurchasedItems = shopItems.where(
      (item) => item.buyerUid == userState.userId && item.isSold
    ).toList();

    final displayName = userState.username;
    final email = firebaseUser?.email ?? userState.userId;
    final coins = userState.coins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 영역
            Row(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFAABCC5),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 코인 정보를 오른쪽에 배치
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Current Coins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min, // 내용만큼만 공간 차지
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.purple, size: 20),
                          const SizedBox(width: 4), // 아이콘과 텍스트 사이 여백
                          Text(
                            '$coins',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const Text(
                        'coins',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Purchase History
            const Text(
              '구매 내역',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: myPurchasedItems.isEmpty && userState.purchaseHistory.isEmpty
                  ? const Text("구매한 일기가 없습니다.", style: TextStyle(color: Colors.grey))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (myPurchasedItems.isNotEmpty) ...myPurchasedItems.map((item) => _buildPurchaseItem(context, item)).toList(),
                        if (userState.purchaseHistory.isNotEmpty) ...userState.purchaseHistory.map((item) => _buildPurchaseItem(context, item)).toList(),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Currently Selling
            const Text(
              '판매 중인 일기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: mySellingItems.isEmpty
                  ? const Text("판매 중인 일기가 없습니다.", style: TextStyle(color: Colors.grey))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mySellingItems.map((item) => _buildSellingItem(context, item)).toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // Sold Items
            const Text(
              '판매 완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: mySoldItems.isEmpty
                  ? const Text("판매 완료된 일기가 없습니다.", style: TextStyle(color: Colors.grey))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mySoldItems.map((item) => _buildSoldItem(context, item)).toList(),
                    ),
            ),

            const SizedBox(height: 40),

            // 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Firebase + 로컬 로그아웃
                  await ref.read(authStateProvider.notifier).logout();
                  // 로그인 화면으로 이동
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItem(BuildContext context, ShopItem item) {
    return Container(
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
    );
  }

  Widget _buildSellingItem(BuildContext context, ShopItem item) {
    return Container(
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
                  "판매 중",
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildSoldItem(BuildContext context, ShopItem item) {
    return Container(
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
                  "판매 완료",
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
