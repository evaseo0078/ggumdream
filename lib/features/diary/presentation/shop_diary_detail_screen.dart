// lib/features/diary/presentation/shop_diary_detail_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/purchase_repository.dart';

class ShopDiaryDetailScreen extends ConsumerWidget {
  final Map<String, String> entry;

  const ShopDiaryDetailScreen({super.key, required this.entry});

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat.yMMMMd().format(dt);
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, size: 56, color: Colors.grey),
      );
    }

    // network 또는 local 파일 판단
    if (path.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          path,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    try {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    } catch (_) {
      // ignore file errors
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.broken_image, size: 56, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateText = _formatDate(entry['date']);
    final summary = entry['summary'] ?? '';
    final interpretation = entry['interpretation'] ?? '';
    final content = entry['content'] ?? '';
    final imagePath = entry['imagePath'];
    final userCoins = entry['userCoins'] != null
        ? int.tryParse(entry['userCoins']!) ?? 0
        : 120;

    return Scaffold(
      appBar: AppBar(title: const Text('Diary detail'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 + id
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text('$userCoins'),
                      ],
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 이미지
              _buildImage(imagePath),
              const SizedBox(height: 16),

              // Summary + interpretation in cards
              if (summary.isNotEmpty) ...[
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.grey[50],
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(summary),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (interpretation.isNotEmpty) ...[
                const Text(
                  'Dream interpretation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.grey[50],
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(interpretation),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Text(
                'Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 본문 영역
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Text(
                        content,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // share or other action - placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shared (placeholder)')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Buy confirmation
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Buy'),
                      content: const Text('Do you want to buy this item?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final purchaseRepo = ref.read(
                              purchaseRepositoryProvider,
                            );
                            purchaseRepo.addPurchase(entry);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('구매가 완료되었습니다.')),
                            );
                          },
                          child: const Text('Buy'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Buy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
