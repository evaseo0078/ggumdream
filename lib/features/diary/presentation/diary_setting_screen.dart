// lib/features/diary/presentation/diary_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_toolbar.dart';
import '../data/hive_diary_repository.dart';
import '../data/purchase_repository.dart';
import 'shop_diary_detail_screen.dart';

class DiarySettingScreen extends ConsumerWidget {
  const DiarySettingScreen({super.key});

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('yyyy. MM. dd').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    final purchaseHistory = purchaseRepo.getPurchasedDiaries();
    return Scaffold(
      appBar: AppBar(title: const Text("Setting")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Username
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

            // 프로필 영역
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 원형 아바타
                const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 48),
                ),
                const SizedBox(width: 16),

                // Coins & ID (읽기 전용) + Edit Profile 버튼
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Coins: 120"), // 예시 값
                      const SizedBox(height: 8),
                      const Text("ID: user_001"), // 예시 값
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Edit profile 동작 추가 예정
                        },
                        child: const Text("Edit Profile"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Purchase History
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: purchaseHistory.map((entry) {
                  return InkWell(
                    onTap: () async {
                      // Hive에서 해당 일기 데이터를 가져옴
                      final repo = ref.read(hiveDiaryRepositoryProvider);
                      final diaryEntry = repo.getEntryById(entry['id']!);
                      if (diaryEntry != null) {
                        // Map<dynamic, dynamic>을 Map<String, String>으로 변환
                        final Map<String, String> stringEntry = diaryEntry.map(
                          (key, value) =>
                              MapEntry(key.toString(), value.toString()),
                        );

                        if (context.mounted) {
                          // ShopDiaryDetailScreen으로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShopDiaryDetailScreen(entry: stringEntry),
                            ),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${_formatDate(entry['date'])}   ${entry['content']}",
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
              ),
            ),
            const SizedBox(height: 24),

            // Sales History
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
              child: const Text(""), // 나중에 데이터 들어갈 자리
            ),
            const SizedBox(height: 16),

            // Reply 버튼
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

      // 하단 공용 네비게이션 바
      bottomNavigationBar: const AppToolbar(currentIndex: 1), // Setting은 1번
    );
  }
}
