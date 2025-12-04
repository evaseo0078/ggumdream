// lib/features/login/account_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import 'auth_repository.dart';
import '../diary/application/user_provider.dart'; // 코인/닉네임 상태
import '../diary/application/shop_provider.dart';
import '../diary/presentation/shop_detail_screen.dart'; // ⚡ import 추가
import '../shop/domain/shop_item.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  // ✨ 프로필 이미지 선택 팝업 띄우기
  void _showProfilePicker(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 한 줄에 5개
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final imageIndex = index + 1; // 1 ~ 5
                  return GestureDetector(
                    onTap: () async {
                      // Repository 직접 호출 or Provider 통해 호출
                      // 여기서는 간단히 AuthRepository 인스턴스를 만들어서 호출하거나
                      // ref를 통해 가져온 provider를 사용해도 됩니다.
                      try {
                        await AuthRepository()
                            .updateProfileImage(userId, imageIndex);
                        if (context.mounted) Navigator.pop(context); // 닫기
                      } catch (e) {
                        debugPrint("Error updating profile: $e");
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile$imageIndex.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebase 현재 유저
    final authRepo = ref.watch(authRepositoryProvider);
    final firebaseUser = authRepo.currentUser;
    final String userId = firebaseUser?.uid ?? '';

    // 앱 내부 유저 상태 (닉네임, 코인 등)
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);

    // Filter current user's items
    final mySellingItems = shopItems
        .where((item) => item.sellerUid == userState.userId && !item.isSold)
        .toList();

    final mySoldItems = shopItems
        .where((item) => item.sellerUid == userState.userId && item.isSold)
        .toList();

    final myPurchasedItems = shopItems
        .where((item) => item.buyerUid == userState.userId && item.isSold)
        .toList();

    final displayName = userState.username;
    final email = firebaseUser?.email ?? userState.userId;
    final coins = userState.coins;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // 텍스트 색상을 흰색으로 변경
        ),
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 영역
              Row(
                children: [
                  // ✨ 프로필 이미지 (StreamBuilder로 실시간 반영)
                  GestureDetector(
                    onTap: () {
                      if (userId.isNotEmpty) {
                        _showProfilePicker(context, userId);
                      }
                    },
                    child: Stack(
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: userId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .snapshots()
                              : const Stream.empty(),
                          builder: (context, snapshot) {
                            int profileIndex = 1; // 기본값
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              profileIndex = data?['profileImageIndex'] ?? 1;
                            }

                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFAABCC5),
                              // 이미지가 있으면 이미지 표시, 없으면 아이콘
                              backgroundImage: AssetImage(
                                  'assets/images/profile$profileIndex.png'),
                              onBackgroundImageError: (_, __) {
                                // 이미지 로드 실패 시 처리 (옵션)
                              },
                            );
                          },
                        ),
                        // 편집 아이콘 (선택 가능함을 표시)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'You have',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Colors.purple, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$coins',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'coins',
                          style: TextStyle(
                            fontSize: 12,
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
                'Purchase History',
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
                child: myPurchasedItems.isEmpty &&
                        userState.purchaseHistory.isEmpty
                    ? const Text("No purchase history.",
                        style: TextStyle(color: Colors.grey))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (myPurchasedItems.isNotEmpty)
                            ...myPurchasedItems.map(
                                (item) => _buildPurchaseItem(context, item)),
                          if (userState.purchaseHistory.isNotEmpty)
                            ...userState.purchaseHistory.map(
                                (item) => _buildPurchaseItem(context, item)),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Currently Selling
              const Text(
                'Currently Selling',
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
                    ? const Text("No items currently selling.",
                        style: TextStyle(color: Colors.grey))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: mySellingItems
                            .map((item) => _buildSellingItem(context, item))
                            .toList(),
                      ),
              ),

              const SizedBox(height: 24),

              // Sold Items
              const Text(
                'Sold Items',
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
                    ? const Text("No sold items.",
                        style: TextStyle(color: Colors.grey))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: mySoldItems
                            .map((item) => _buildSoldItem(context, item))
                            .toList(),
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

                    // 모든 provider 상태를 명시적으로 새로고침
                    ref.invalidate(userProvider);
                    ref.invalidate(shopProvider);

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
      ),
    );
  }

  Widget _buildPurchaseItem(BuildContext context, ShopItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(item: item, isPurchased: true),
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
            builder: (context) => ShopDetailScreen(item: item, isPurchased: false),
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
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
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
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
