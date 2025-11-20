import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/diary_entry.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import 'diary_editor_screen.dart'; // 에디터 import 필요
import '../application/diary_providers.dart';

class DiaryDetailScreen extends ConsumerWidget {
  final DiaryEntry? entry;
  final String? entryId;

  const DiaryDetailScreen({super.key, this.entry, this.entryId}) : assert(entry != null || entryId != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryList = ref.watch(diaryListProvider);
    DiaryEntry? resolvedEntry = entry;
    if (resolvedEntry == null && entryId != null) {
      try {
        resolvedEntry = diaryList.firstWhere((e) => e.id == entryId);
      } catch (_) {
        resolvedEntry = null;
      }
    }

    if (resolvedEntry == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(color: Colors.black), title: const Text('Diary')),
        body: const Center(child: Text('Diary not found')),
      );
    }

    final e = resolvedEntry;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          DateFormat('yyyy/MM/dd (E)').format(e.date),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Stencil'),
        ),
        // ⚡ [추가됨] 수정 버튼
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.black),
            tooltip: "Edit Diary",
            onPressed: () {
              // 수정 화면으로 이동 (현재 entry를 전달)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryEditorScreen(
                    selectedDate: e.date, // 날짜는 형식상 전달 (에디터 내부에서 entry.date 사용)
                    existingEntry: e,     // ⚡ 핵심: 기존 데이터를 넘겨줌
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (e.imageUrl != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(
                            imageUrl: e.imageUrl!,
                            tag: 'diaryImage_${e.id}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'diaryImage_${e.id}',
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        image: e.imageUrl != null
                            ? DecorationImage(image: NetworkImage(e.imageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: e.imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildResultBox("Summary", e.summary ?? "No summary"),
                      const SizedBox(height: 10),
                      _buildResultBox("Interpretation", e.interpretation ?? "No interpretation"),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            const Text("My Dream", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}