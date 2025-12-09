// lib/features/diary/presentation/diary_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/app_toolbar.dart';
import '../application/user_provider.dart';
import '../data/purchase_repository.dart';
import 'shop_detail_screen.dart';
import '../../shop/domain/shop_item.dart';

final purchaseHistoryProvider =
    FutureProvider.autoDispose<List<ShopItem>>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchases();
});

class DiarySettingScreen extends ConsumerWidget {
  const DiarySettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchaseHistoryProvider);
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Setting")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Your Username",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Coins: ${userState.coins}"),
                      const SizedBox(height: 8),
                      Text("ID: ${userState.userId.isEmpty ? '-': userState.userId}"),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Edit Profile"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Purchase History",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: purchases.when(
                data: (history) {
                  if (history.isEmpty) {
                    return const Text("No purchases yet.");
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: history.map((entry) {
                      final dateText =
                          DateFormat('yyyy. MM. dd').format(entry.date);
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShopDetailScreen(item: entry),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "$dateText   ${entry.content}",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Failed to load purchases: $e'),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sales History",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(""), // Placeholder for future sales history
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Reply"),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppToolbar(currentIndex: 1),
    );
  }
}
