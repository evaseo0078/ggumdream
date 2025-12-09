import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';
import '../../../home/home_shell.dart';
import '../../shop/domain/shop_item.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../data/purchase_repository.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';
import 'package:ggumdream/shared/widgets/glass_card.dart';

class ShopDetailScreen extends ConsumerWidget {
  final ShopItem item;
  final bool isPurchased;

  const ShopDetailScreen({super.key, required this.item, this.isPurchased = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isOwner = item.sellerUid == userState.userId; // 판매자인지 확인
    final isPurchasedByMe = item.buyerUid == userState.userId; // ⚡ 구매자인지 확인
    final dateText = DateFormat('yyyy.MM.dd').format(item.date);

    // ⚡ 판매된 일기는 접근 불가 (단, 구매자는 접근 가능)
    if (item.isSold && !isPurchasedByMe) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Color.fromARGB(255, 255, 255, 255)),
          title: const Text('Access Denied', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'This diary has been sold',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Sold diaries can no longer be accessed.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 220, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
        leading: const BackButton(color: Color.fromARGB(255, 255, 255, 255)),
        title: Text(
          "$dateText (by ${item.ownerName})",
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
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
                      if (!isPurchased && !isOwner && !isPurchasedByMe)
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
                        (isPurchased || isOwner || isPurchasedByMe) 
                            ? (item.summary ?? "No summary available")
                            : "🔒 Purchase to view summary",
                        isBlurred: !isPurchased && !isOwner && !isPurchasedByMe,
                      ),
                      const SizedBox(height: 10),
                      _buildResultBox(
                        "Interpretation",
                        (isPurchased || isOwner || isPurchasedByMe) 
                            ? (item.interpretation ?? "No interpretation available")
                            : "🔒 Purchase to view interpretation",
                        isBlurred: !isPurchased && !isOwner && !isPurchasedByMe,
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
                  if (!isPurchased && !isOwner && !isPurchasedByMe)
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
            if (!isPurchased && !item.isSold && !isOwner && !isPurchasedByMe)
              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: GlassCard(
                    radius: 25,
                    opacity: 0.5,
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
                          color: Color.fromARGB(255, 0, 0, 0),
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

  // 구매 확정 로직 – Cloud Functions purchaseMarketItem만 호출
  Future<void> _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 이 화면에서 보고 있는 아이템
    final shopItem = item; // 클래스 필드 ShopItem item

    // 1) 로그인 확인
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    // 2) 코인 잔액 체크 (부족하면 미리 막기)
    final userState = ref.read(userProvider); // 이미 쓰고 있는 유저 프로바이더라고 가정
    final currentCoins = userState.coins ?? 0;

    if (currentCoins < shopItem.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins to purchase this item.')),
      );
      return;
    }

    try {
      // 3) asia-northeast3 리전에 배포된 purchaseMarketItem 함수 호출
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable = functions.httpsCallable('purchaseMarketItem');

      final result = await callable.call(<String, dynamic>{
        'itemId': shopItem.id,
      });

      if (kDebugMode) {
        print('purchaseMarketItem result: ${result.data}');
      }

      // 4) UI 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase completed!')),
      );

      // Firestore 쓰기는 전부 Cloud Functions(admin)에서 처리하므로
      // 여기서는 아무것도 직접 write 하지 않습니다.
      // (userProvider / shopProvider 가 snapshot을 listen 중이라 자동으로 갱신됨)

      Navigator.pop(context); // 디테일 화면 닫기 등
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.code} ${e.message ?? ''}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  }


}
