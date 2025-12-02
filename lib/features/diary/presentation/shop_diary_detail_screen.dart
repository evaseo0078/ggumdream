// lib/features/diary/presentation/shop_diary_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shop/domain/shop_item.dart';

class ShopDiaryDetailScreen extends StatelessWidget {
  final ShopItem item;

  const ShopDiaryDetailScreen({super.key, required this.item});

  String _formatDate(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(item.date);

    return Scaffold(
      appBar: AppBar(
        title: Text('${item.ownerName}\'s dream'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _buildImage(item.imageUrl),
            const SizedBox(height: 16),
            _buildInfoBox("Summary", item.summary ?? 'No summary'),
            const SizedBox(height: 12),
            _buildInfoBox("Interpretation", item.interpretation ?? 'No interpretation'),
            const SizedBox(height: 16),
            const Text(
              "Dream Content",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, size: 56, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildInfoBox(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
