import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shop/domain/shop_item.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import 'shop_detail_screen.dart';
import 'user_dreams_grid_screen.dart'; // ⚡ import 추가
import '../../../shared/widgets/glass_card.dart';

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

    // ⚡ 필터링 후 정렬: 판매 안된 일기 먼저, 판매된 일기 나중에
    final filteredItems = _showMySales
        ? shopItems.where((item) => item.sellerUid == userState.userId).toList()
        : shopItems.where((item) => item.sellerUid != userState.userId).toList();

    // 정렬: isSold=false 가 먼저, isSold=true 가 나중에
    filteredItems.sort((a, b) {
      if (a.isSold == b.isSold) {
        // 같은 상태면 생성 시간 역순 (최신순)
        return (b.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now());
      }
      return a.isSold ? 1 : -1; // false(0) < true(1), 즉 판매 안된 것 먼저
    });

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/shop_background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(1),
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 192, 171, 255),
                  Color.fromARGB(255, 192, 171, 255),
                  Color.fromARGB(0, 255, 255, 255),
                  Color.fromARGB(0, 255, 255, 255),
                  Color.fromARGB(198, 184, 192, 255),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: const Text(
                    "GGUM store",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Stencil',
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
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
                            child: Icon(Icons.star,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          GlassCard(
                            radius: 12,
                            opacity: 0.4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: Text(
                                "${userState.coins}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildShopItem(
                              context,
                              ref,
                              filteredItems[index],
                              userState.userId,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
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
      child: GlassCard(
        radius: 20,
        opacity: isActive ? 0.3 : 0.1,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 여기서 sellerUid → Firestore users/{uid} 를 구독해서
  ///     항상 최신 nickname 을 가져온다.
  Widget _buildShopItem(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
    String currentUserId,
  ) {
    final isMine = item.sellerUid == currentUserId;
    final dateText = DateFormat('yyyy.MM.dd').format(item.date);

    final sellerUserAsync = ref.watch(userByIdProvider(item.sellerUid));

    return sellerUserAsync.when(
      loading: () => _buildShopItemContent(
        context: context,
        item: item,
        dateText: dateText,
        ownerName: 'Loading...',
        isMine: isMine,
      ),
      error: (_, __) => _buildShopItemContent(
        context: context,
        item: item,
        dateText: dateText,
        ownerName: item.ownerName ?? 'Unknown',
        isMine: isMine,
      ),
      data: (sellerUser) {
        final ownerName =
            sellerUser?.username ?? item.ownerName ?? 'Dreamer';
        return _buildShopItemContent(
          context: context,
          item: item,
          dateText: dateText,
          ownerName: ownerName,
          isMine: isMine,
        );
      },
    );
  }

  /// 실제 카드 UI는 이 함수에서 한 번만 정의
  Widget _buildShopItemContent({
    required BuildContext context,
    required ShopItem item,
    required String dateText,
    required String ownerName,
    required bool isMine,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(item: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          radius: 14,
          opacity: 0.1, // Default opacity
          child: Container(
            decoration: BoxDecoration(
              color: item.isSold
                  ? const Color.fromARGB(255, 200, 200, 200)
                      .withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: item.isSold
                  ? Border.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 2.0,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 + Owner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: item.isSold
                            ? const Color.fromARGB(255, 89, 89, 89)
                            : const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDreamsGridScreen(
                              ownerName: ownerName,      // ✅ 최신 닉네임
                              sellerUid: item.sellerUid,
                            ),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          children: [
                            const TextSpan(text: "Owner: "),
                            TextSpan(
                              text: ownerName,           // ✅ Firestore 기준
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 썸네일
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: item.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.image,
                              color: item.isSold
                                  ? Colors.grey[400]
                                  : Colors.grey,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Summary + 가격
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.summary ?? "Summary hidden",
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              decoration: item.isSold
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (item.isSold)
                                const Text(
                                  "Sold",
                                  style: TextStyle(color: Colors.grey),
                                )
                              else if (isMine)
                                const Text(
                                  "Selling",
                                  style:
                                      TextStyle(color: Colors.orange),
                                ),
                              const SizedBox(width: 12),
                              WobblyPriceTag(
                                price: item.price,
                                isSold: item.isSold,
                                backgroundColor:
                                    const Color.fromARGB(108, 197, 171, 255),
                              ),
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
        ),
      ),
    );
  }
}

class WobblyPriceTag extends StatelessWidget {
  final int price;
  final bool isSold;
  final Color backgroundColor;

  const WobblyPriceTag({
    super.key,
    required this.price,
    required this.isSold,
    this.backgroundColor = const Color(0xFFAABCC5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSold ? Colors.grey : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        "$price coins",
        style: TextStyle(
          color: isSold
              ? const Color.fromARGB(255, 63, 63, 63)
              : const Color.fromARGB(255, 255, 255, 255),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
