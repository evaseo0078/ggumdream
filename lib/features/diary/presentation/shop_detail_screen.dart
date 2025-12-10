// lib/features/diary/presentation/shop_detail_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';

import '../../shop/domain/shop_item.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';

/// ---------------------------------------------------------------------------
/// 공통 Glass 카드 (DiaryDetailScreen 과 같은 스타일)
/// ---------------------------------------------------------------------------
Widget glassCard({
  required Widget child,
  double radius = 22,
  double opacity = 0.18,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class ShopDetailScreen extends ConsumerWidget {
  final ShopItem item;
  final bool isPurchased; // 구매 이력에서 들어오면 true

  const ShopDetailScreen({
    super.key,
    required this.item,
    this.isPurchased = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isOwner = item.sellerUid == userState.userId;
    final isPurchasedByMe = item.buyerUid == userState.userId;
    final dateText = DateFormat('yyyy.MM.dd (E)').format(item.date);

    // 판매자의 최신 닉네임 실시간 반영
    final sellerUserAsync = ref.watch(userByIdProvider(item.sellerUid));
    final ownerName = sellerUserAsync.maybeWhen(
      data: (u) => u?.username ?? (item.ownerName ?? 'Dreamer'),
      orElse: () => item.ownerName ?? 'Dreamer',
    );

    // 이미 판매 완료 + 내가 구매자도 아니고, 판매자도 아니면 접근 차단
    if (item.isSold && !isPurchasedByMe && !isOwner) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.white),
          title: const Text(
            'Access Denied',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFC0ABFF),
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

    // 전체 내용 열람 가능한지 여부 (소유자 / 이미 구매 / 구매 이력 화면에서 들어온 경우)
    final bool canViewFull = isPurchased || isOwner || isPurchasedByMe;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          dateText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Stencil',
          ),
        ),
        backgroundColor: const Color(0xFFC0ABFF),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6E6FA),
              Color(0xFFC0ABFF),
              Color(0xFF99B0FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------------------------------------
                // 상단 이미지 카드 (DiaryDetailScreen 첫 번째 스샷 같은 느낌)
                // -----------------------------------------------------------------
                if (item.imageUrl != null)
                  glassCard(
                    radius: 26,
                    child: GestureDetector(
                      onTap: canViewFull
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    imageUrl: item.imageUrl!,
                                    tag: 'shop-image-${item.id}',
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Hero(
                        tag: 'shop-image-${item.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              if (!canViewFull)
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.15),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (item.imageUrl != null) const SizedBox(height: 20),

                // -----------------------------------------------------------------
                // Summary / Interpretation 카드
                // -----------------------------------------------------------------
                glassCard(
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary
                        const Text(
                          "Summary",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          canViewFull
                              ? (item.summary ?? "No summary available.")
                              : "🔒 Purchase to view summary.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Interpretation
                        const Text(
                          "Interpretation",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          canViewFull
                              ? (item.interpretation ??
                                  "No interpretation available.")
                              : "🔒 Purchase to view interpretation.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // -----------------------------------------------------------------
                // Dream Story 카드
                // -----------------------------------------------------------------
                glassCard(
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Dream Story",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "by $ownerName",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        if (!canViewFull)
                          Positioned.fill(
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        color: Colors.black54,
                                        size: 28,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Purchase to read the dream.",
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // -----------------------------------------------------------------
                // 구매 버튼 (내 것이 아니고, 아직 안 팔렸고, 내가 이미 산 것도 아닐 때)
                // -----------------------------------------------------------------
                if (!canViewFull && !item.isSold && !isOwner)
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _confirmPurchase(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF6A4ACF),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          "Buy for ${item.price} coins",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 구매 확정 로직 – purchaseMarketItem Cloud Function 호출
  // ---------------------------------------------------------------------------
  Future<void> _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    // 코인 잔액 체크
    final userState = ref.read(userProvider);
    final currentCoins = userState.coins;
    if (currentCoins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Not enough coins to purchase this item.'),
        ),
      );
      return;
    }

    try {
      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      final callable =
          functions.httpsCallable('purchaseMarketItem');

      final result = await callable.call(<String, dynamic>{
        'itemId': item.id,
      });

      if (kDebugMode) {
        print('purchaseMarketItem result: ${result.data}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase completed!')),
      );

      // Firestore → snapshot listening 으로 user/shop 상태 자동 갱신됨
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Purchase failed: ${e.code} ${e.message ?? ''}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  }
}
