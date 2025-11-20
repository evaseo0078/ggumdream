// lib/features/auth/presentation/account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/user_provider.dart';
import '../../diary/presentation/shop_detail_screen.dart';
import '../../shop/domain/shop_item.dart'; // ShopItem 위치 확인
import '../../diary/presentation/stats_screen.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart'; // FIX: 패키지 경로로 변경

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Account Page",
            style: TextStyle(color: Colors.black26, fontSize: 16)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. 유저네임 (WobblyContainer 적용)
            WobblyContainer(
              backgroundColor: Colors.white,
              borderColor: Colors.black87,
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(vertical: 12),
              constraints: const BoxConstraints(minWidth: double.infinity),
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
                  child:
                      Icon(Icons.person_outline, size: 50, color: Colors.black),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                              width: 40,
                              child: Text("Coins",
                                  style: TextStyle(fontSize: 12))),
                          Expanded(
                            // Coins 값 표시 박스 (WobblyContainer 적용)
                            child: WobblyContainer(
                              backgroundColor: Colors.grey.shade300,
                              borderColor: Colors.transparent,
                              borderRadius: 4,
                              padding: const EdgeInsets.only(left: 8),
                              constraints: const BoxConstraints(minHeight: 24),
                              child: Text("${userState.coins}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                              width: 40,
                              child:
                                  Text("ID", style: TextStyle(fontSize: 12))),
                          Expanded(
                            // ID 값 표시 박스 (WobblyContainer 적용)
                            child: WobblyContainer(
                              backgroundColor: Colors.grey.shade300,
                              borderColor: Colors.transparent,
                              borderRadius: 4,
                              padding: const EdgeInsets.only(left: 8),
                              constraints: const BoxConstraints(minHeight: 24),
                              child: Text(userState.userId),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 30,
                          // Edit Profile 버튼 (WobblyContainer 적용)
                          child: WobblyContainer(
                            backgroundColor: const Color(0xFFAABCC5),
                            borderColor: Colors.black12,
                            borderRadius: 12,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text("Edit Profile",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 24),

            // ✨ [추가됨] 통계 분석 버튼 (WobblyContainer 적용)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: WobblyContainer(
                backgroundColor: Colors.deepPurple.shade300,
                borderColor: Colors.black,
                borderRadius: 12,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StatsScreen()),
                    );
                  },
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  label: const Text("Analyze Sleep & Dreams",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 3. Purchase History
            const Align(
                alignment: Alignment.centerLeft,
                child:
                    Text("Purchase History", style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            // Purchase History Box (WobblyContainer 적용)
            WobblyContainer(
              backgroundColor: Colors.white,
              borderColor: Colors.black12,
              borderRadius: 4,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: userState.purchaseHistory.isEmpty
                  ? const Text("No items purchased.",
                      style: TextStyle(color: Colors.grey))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: userState.purchaseHistory
                          .map((item) => _buildHistoryItem(context, item))
                          .toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // 4. Sales History
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Sales History", style: TextStyle(fontSize: 12))),
            const SizedBox(height: 8),
            // Sales History Box (WobblyContainer 적용)
            WobblyContainer(
              backgroundColor: Colors.white,
              borderColor: Colors.black12,
              borderRadius: 4,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: userState.salesHistory.isEmpty
                  ? const Text("No sales yet.",
                      style: TextStyle(color: Colors.grey))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: userState.salesHistory
                          .map((item) =>
                              _buildHistoryItem(context, item, isSale: true))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ShopItem item,
      {bool isSale = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShopDetailScreen(item: item)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          children: [
            Icon(isSale ? Icons.sell : Icons.shopping_bag,
                size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              // ⚡ [수정됨] content 대신 summary 표시 (없으면 content)
              child: Text(
                "${item.summary ?? item.content}",
                style: const TextStyle(
                    fontSize: 12, decoration: TextDecoration.underline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "${item.price}c",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
