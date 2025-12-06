import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/diary_entry.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import 'diary_editor_screen.dart'; // 에디터 import 필요
import '../application/diary_providers.dart';
import '../application/shop_provider.dart'; // 판매 상태 체크용
import '../application/user_provider.dart'; // 사용자 확인용
import '../../../shared/widgets/glass_card.dart'; // GlassCard import 추가
import 'dart:ui'; // ImageFilter를 사용하기 위해 추가

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
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);

    // ⚡ 판매중인 일기인지 확인 (마켓에 등록되었지만 아직 안 팔린 경우)
    final sellingItems = shopItems.where(
      (item) => item.diaryId == e.id && !item.isSold,
    ).toList();
    final isCurrentlySelling = sellingItems.isNotEmpty;
    final isOwner = isCurrentlySelling && sellingItems.first.sellerUid == userState.userId;

    // ⚡ 팔린 일기 접근 제한 (단, 판매자 본인이 판매중인 일기는 예외)
    if (e.isSold && !isOwner) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          title: const Text('Access Denied', style: TextStyle(color: Colors.black)),
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

    return Scaffold(
      extendBody: true, // Ensures the gradient fills the entire screen
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 192, 171, 255), // 색깔 변경
        leading: const BackButton(color: Color.fromARGB(255, 255, 255, 255)),
        title: Text(
          DateFormat('yyyy/MM/dd (E)').format(e.date),
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold, fontFamily: 'Stencil',),
        ),
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
                        width: 180,
                        height: 180,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Summary",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                              e.summary ?? "No summary",
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                "Interpretation",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 7),
              GlassCard(
                radius: 8,
                opacity: 0.2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.interpretation ?? "No interpretation",
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
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
      // ⚡ FloatingActionButton으로 편집 버튼 추가
      floatingActionButton: _buildEditFAB(context, ref, e),
    );
  }

  /// 편집 가능한지 확인: 판매중이 아니고 판매완료도 아닌 경우만
  bool _canEdit(List<dynamic> shopItems, DiaryEntry entry) {
    // 1. 이미 팔린 일기는 편집 불가
    if (entry.isSold) return false;
    
    // 2. 현재 마켓에 등록된(판매중인) 일기는 편집 불가
    final isCurrentlyListed = shopItems.any((item) => 
      item is Map && item['diaryId'] == entry.id && item['isSold'] == false
    );
    if (isCurrentlyListed) return false;
    
    return true;
  }

  Widget? _buildEditFAB(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    final shopItems = ref.watch(shopProvider);
    
    // 편집 가능한 경우만 FAB 표시
    if (_canEdit(shopItems, entry)) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryEditorScreen(
                selectedDate: entry.date,
                existingEntry: entry,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }
    return null; // 편집 불가능한 경우 null 반환
  }

  
}