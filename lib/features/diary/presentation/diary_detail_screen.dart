import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/diary_entry.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import 'diary_editor_screen.dart'; // 에디터 import 필요
import '../application/diary_providers.dart';
import '../../../shared/widgets/glass_card.dart'; // GlassCard import 추가

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
      extendBody: true, // Ensures the gradient fills the entire screen
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 192, 171, 255), // 색깔 변경
        leading: const BackButton(color: Color.fromARGB(255, 255, 255, 255)),
        title: Text(
          DateFormat('yyyy/MM/dd (E)').format(e.date),
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold, fontFamily: 'Stencil',),
          
        ),
        // ⚡ [추가됨] 수정 버튼
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color.fromARGB(255, 255, 255, 255)),
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
      body: Container(
        height: double.infinity, // Fill the entire height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6E6FA), // Light purple
              Color.fromARGB(255, 168, 152, 255),
              Color.fromARGB(255, 152, 176, 255) // Dark purple
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5), // 이미지와 Summary 텍스트의 시작점을 맞추기 위해 추가
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
                        Padding(
                          padding: EdgeInsets.only(right:270.0), // 수치적으로 조정 가능
                          child: Text(
                            "Summary",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        // padding 값을 변경하여 위치를 조정하세요.
                        // 예: EdgeInsets.only(left: 32.0), EdgeInsets.symmetric(horizontal: 20.0) 등
                        const SizedBox(height: 7),
                        GlassCard(
                          radius: 8,
                          opacity: 0.2,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.summary ?? "No summary",
                              style: const TextStyle(fontSize: 15),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Padding(
                          padding: EdgeInsets.only(right: 245.0), // 수치적으로 조정 가능
                          child: Text(
                            "Interpretation",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 7),
                        GlassCard(
                          radius: 8,
                          opacity: 0.2,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.interpretation ?? "No interpretation",
                              style: const TextStyle(fontSize: 13),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              const Text("My Dream", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 255, 255, 255))),
              const SizedBox(height: 8),
              GlassCard(
                radius: 8,
                opacity: 0.2,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}