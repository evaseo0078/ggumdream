// lib/features/diary/presentation/diary_detail_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/diary_entry.dart';
import '../application/diary_providers.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import 'diary_editor_screen.dart';

/// 공통으로 쓰는 glass 카드
Widget glassCard({
  required Widget child,
  double radius = 20,
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

class DiaryDetailScreen extends ConsumerWidget {
  /// 이미 DiaryEntry 객체를 넘기는 경우
  final DiaryEntry? entry;

  /// id만 넘겨서 Provider에서 찾아오는 경우
  final String? entryId;

  const DiaryDetailScreen({
    super.key,
    this.entry,
    this.entryId,
  }) : assert(entry != null || entryId != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryList = ref.watch(diaryListProvider);

    // entry가 없으면 id로 조회
    DiaryEntry? resolvedEntry = entry;
    if (resolvedEntry == null && entryId != null) {
      try {
        resolvedEntry =
            diaryList.firstWhere((e) => e.id == entryId);
      } catch (_) {
        resolvedEntry = null;
      }
    }

    if (resolvedEntry == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Diary',
            style:
                TextStyle(fontFamily: 'Stencil', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFC0ABFF),
        ),
        body: const Center(
          child: Text('Diary not found.'),
        ),
      );
    }

    final dateStr =
        DateFormat('yyyy.MM.dd (E)').format(resolvedEntry.date);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          dateStr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Stencil',
          ),
        ),
        backgroundColor: const Color(0xFFC0ABFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiaryEditorScreen(
                    selectedDate: resolvedEntry!.date,
                    existingEntry: resolvedEntry,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _confirmDelete(context, ref, resolvedEntry!.id),
          ),
        ],
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
                // 상단 카드: 날짜 + 기분 + 수면시간
                glassCard(
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          resolvedEntry.mood,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                resolvedEntry.sleepDuration >= 0
                                    ? "Sleep: ${resolvedEntry.sleepDuration.toStringAsFixed(1)} h"
                                    : "Sleep: unknown",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 이미지 카드
                if (resolvedEntry.imageUrl != null)
                  glassCard(
                    radius: 22,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrl: resolvedEntry!.imageUrl!,
                              tag: 'diary-image-${resolvedEntry.id}',
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'diary-image-${resolvedEntry.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              resolvedEntry.imageUrl!,
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
                        ),
                      ),
                    ),
                  ),

                if (resolvedEntry.imageUrl != null)
                  const SizedBox(height: 20),

                // 요약 / 해석 카드
                if (resolvedEntry.summary != null ||
                    resolvedEntry.interpretation != null)
                  glassCard(
                    radius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (resolvedEntry.summary != null) ...[
                            const Text(
                              "Summary",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              resolvedEntry.summary!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (resolvedEntry.interpretation != null) ...[
                            const Text(
                              "Interpretation",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              resolvedEntry.interpretation!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                if (resolvedEntry.summary != null ||
                    resolvedEntry.interpretation != null)
                  const SizedBox(height: 20),

                // 원문 내용 카드
                glassCard(
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
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
                          resolvedEntry.content,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
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

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String entryId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Diary"),
        content:
            const Text("Are you sure you want to delete this diary entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(diaryListProvider.notifier).deleteDiary(entryId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Diary deleted.")),
              );
              Navigator.pop(context); // detail 화면 닫기
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
