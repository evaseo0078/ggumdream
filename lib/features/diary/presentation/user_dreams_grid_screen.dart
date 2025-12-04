// lib/features/diary/presentation/user_dreams_grid_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/shop_provider.dart';
import 'shop_detail_screen.dart';

/// 특정 사용자의 꿈들을 그리드로 보여주는 화면
class UserDreamsGridScreen extends ConsumerWidget {
  final String ownerName;
  final String sellerUid;

  const UserDreamsGridScreen({
    super.key,
    required this.ownerName,
    required this.sellerUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopItems = ref.watch(shopProvider);
    
    // 해당 사용자의 아이템만 필터링
    final userItems = shopItems
        .where((item) => item.sellerUid == sellerUid)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "$ownerName's Dreams",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Stencil',
          ),
        ),
        centerTitle: true,
      ),
      body: userItems.isEmpty
          ? const Center(
              child: Text(
                "No dreams available",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 가로 3개
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1, // 정사각형
                ),
                itemCount: userItems.length,
                itemBuilder: (context, index) {
                  final item = userItems[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopDetailScreen(item: item),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 이미지 표시
                          if (item.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            )
                          else
                            // 이미지가 없는 경우 기본 아이콘
                            const Center(
                              child: Icon(Icons.image, color: Colors.grey, size: 40),
                            ),
                          
                          // Sold 뱃지
                          if (item.isSold)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "SOLD",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          
                          // 가격 표시 (하단 오른쪽)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${item.price}c",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
