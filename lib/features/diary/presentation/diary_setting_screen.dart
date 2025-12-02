// lib/features/diary/presentation/diary_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/app_toolbar.dart';
import '../application/user_provider.dart';
import '../data/purchase_repository.dart';
import 'shop_diary_detail_screen.dart';
import '../../shop/domain/shop_item.dart';
import '../../login/auth_repository.dart';

final purchaseHistoryProvider =
    FutureProvider.autoDispose<List<ShopItem>>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchases();
});

class DiarySettingScreen extends ConsumerStatefulWidget {
  const DiarySettingScreen({super.key});

  @override
  ConsumerState<DiarySettingScreen> createState() => _DiarySettingScreenState();
}

class _DiarySettingScreenState extends ConsumerState<DiarySettingScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final List<String> _profileImages = const [
    'assets/images/profile1.png',
    'assets/images/profile2.png',
    'assets/images/profile3.png',
    'assets/images/profile4.png',
    'assets/images/profile5.png',
  ];

  String? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nicknameController.text = user.username;
    _selectedImage =
        user.profileImage.isNotEmpty ? user.profileImage : _profileImages.first;

    ref.listen(userProvider, (previous, next) {
      if (previous?.username != next.username) {
        _nicknameController.text = next.username;
      }
      if (previous?.profileImage != next.profileImage) {
        _selectedImage = next.profileImage;
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final user = ref.read(userProvider);
    final profileImage = _selectedImage ?? _profileImages.first;
    if (nickname.isEmpty || user.userId.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateUserProfile(
            uid: user.userId,
            nickname: nickname,
            profileImage: profileImage,
          );

      await ref.read(userProvider.notifier).setUser(
            username: nickname,
            userId: user.userId,
            coins: user.coins,
            profileImage: profileImage,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('변경사항이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 업데이트 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchaseHistoryProvider);
    final userState = ref.watch(userProvider);
    final currentDisplayImage =
        _selectedImage ?? userState.profileImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontFamily: 'HandWriting'),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _nicknameController,
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
                CircleAvatar(
                  radius: 48,
                  backgroundImage: AssetImage(currentDisplayImage),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Coins: ${userState.coins}"),
                      const SizedBox(height: 8),
                      Text(
                          "ID: ${userState.userId.isEmpty ? '-' : userState.userId}"),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Edit Profile"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '프로필 이미지 선택',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _profileImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final path = _profileImages[index];
                final isSelected = currentDisplayImage == path;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = path;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.blueAccent, width: 3)
                          : null,
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(path),
                    ),
                  ),
                );
              },
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
                              builder: (_) => ShopDiaryDetailScreen(item: entry),
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
