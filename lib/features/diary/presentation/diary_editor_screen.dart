import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/ggum_button.dart';
import '../application/diary_providers.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart'; // FIX: 패키지 경로로 변경

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  // ⚡ [추가됨] 수정할 기존 일기 (없으면 새 작성)
  final DiaryEntry? existingEntry;

  const DiaryEditorScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry, // 선택적 파라미터
  });

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  late TextEditingController _textController; // late로 변경
  double _sleepDuration = 7.0; 
  bool _isSleepUnknown = false; 

  @override
  void initState() {
    super.initState();
    // ⚡ [로직 추가] 기존 일기가 있으면 내용 채워넣기 (수정 모드)
    if (widget.existingEntry != null) {
      _textController = TextEditingController(text: widget.existingEntry!.content);
      if (widget.existingEntry!.sleepDuration < 0) {
        _isSleepUnknown = true;
      } else {
        _sleepDuration = widget.existingEntry!.sleepDuration;
      }
    } else {
      _textController = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something first.")),
      );
      return;
    }

    final finalSleepDuration = _isSleepUnknown ? -1.0 : _sleepDuration;
    final bool isEditMode = widget.existingEntry != null;

    final draftEntry = DiaryEntry(
      id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
      date: isEditMode ? widget.existingEntry!.date : widget.selectedDate,
      content: text,
      mood: isEditMode ? widget.existingEntry!.mood : "📝",
      sleepDuration: finalSleepDuration,
      isDraft: true,
      isSold: isEditMode ? widget.existingEntry!.isSold : false,
    );

    if (isEditMode) {
      ref.read(diaryListProvider.notifier).updateDiary(draftEntry);
    } else {
      ref.read(diaryListProvider.notifier).addDiary(draftEntry);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft saved!")),
    );
    Navigator.pop(context);
  }

  Future<void> _processAndSave() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    const int minLength = 20;
    if (text.length < minLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Too short! Please write at least $minLength characters."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFAABCC5)),
            SizedBox(height: 20),
            Text("Re-Analyzing Dream...", style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none)),
          ],
        ),
      ),
    );

    try {
      final llmService = ref.read(llmServiceProvider);

      // ✨ 항상 AI를 다시 돌립니다 (새 이미지, 새 요약 생성)
      final results = await Future.wait([
        llmService.generateImage(text),
        llmService.analyzeDream(text),
      ]);

      final imageUrl = results[0] as String;
      final analysis = results[1] as Map<String, String>;

      final finalSleepDuration = _isSleepUnknown ? -1.0 : _sleepDuration;

      // ⚡ [핵심 로직] 수정 모드 vs 새 작성 모드 구분
      final bool isEditMode = widget.existingEntry != null;

      final newEntry = DiaryEntry(
        // 수정이면 기존 ID 유지, 새 글이면 새 ID 생성
        id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
        // 수정이면 기존 날짜 유지, 새 글이면 선택 날짜
        date: isEditMode ? widget.existingEntry!.date : widget.selectedDate,
        content: text,
        imageUrl: imageUrl,
        summary: analysis['summary'],
        interpretation: analysis['interpretation'],
        mood: analysis['mood'] ?? "🌿",
        sleepDuration: finalSleepDuration, 
        isSold: isEditMode ? widget.existingEntry!.isSold : false, // 판매 상태 유지
      );

      // 저장 (Update or Add)
      if (isEditMode) {
        ref.read(diaryListProvider.notifier).updateDiary(newEntry);
      } else {
        ref.read(diaryListProvider.notifier).addDiary(newEntry);
        // ⚡ [중요] 코인 보상은 '새 글'일 때만 지급 (수정 남발 방지)
        ref.read(userProvider.notifier).earnCoins(10);
      }

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditMode ? "Diary Updated!" : "Diary Posted! +10 coins")),
      );

      // 상세 화면으로 이동 (새 데이터로 교체)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryDetailScreen(entryId: newEntry.id),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to analyze.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 날짜 표시 (수정 모드면 기존 날짜)
    final displayDate = widget.existingEntry?.date ?? widget.selectedDate;
    final dateStr = DateFormat('yyyy/MM/dd (E)').format(displayDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(dateStr,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Stencil')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How long did you sleep?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 수면 시간 입력 박스 (WobblyContainer 적용)
            WobblyContainer(
              backgroundColor: Colors.white,
              borderColor: Colors.black12,
              borderRadius: 12,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isSleepUnknown = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSleepUnknown
                                  ? const Color(0xFFAABCC5)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(11)),
                            ),
                            alignment: Alignment.center,
                            child: Text("Input Time", style: TextStyle(fontWeight: FontWeight.bold, color: !_isSleepUnknown ? Colors.black : Colors.grey)),
                          ),
                        ),
                      ),
                      const SizedBox(
                          width: 1,
                          height: 40,
                          child: VerticalDivider()), // 세로 선은 그대로 유지
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isSleepUnknown = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSleepUnknown
                                  ? const Color(0xFFAABCC5)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(11)),
                            ),
                            alignment: Alignment.center,
                            child: Text("Don't Know", style: TextStyle(fontWeight: FontWeight.bold, color: _isSleepUnknown ? Colors.black : Colors.grey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isSleepUnknown
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text("Sleep duration will not be recorded.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          )
                        : Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.bedtime, color: Colors.deepPurple),
                                  Text("${_sleepDuration.toStringAsFixed(1)} Hours", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                ],
                              ),
                              Slider(
                                value: _sleepDuration,
                                min: 0, max: 16, divisions: 32, 
                                activeColor: const Color(0xFFAABCC5), inactiveColor: Colors.grey[300],
                                onChanged: (value) => setState(() => _sleepDuration = value),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text("Write your dream (min 20 chars)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              // 꿈 내용 입력 박스 (WobblyContainer 적용)
              child: WobblyContainer(
                backgroundColor: Colors.white,
                borderColor: Colors.black12,
                borderRadius: 8,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Describe what happened in your dream...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GgumButton(
                  width: 120,
                  text: "SAVE DRAFT",
                  onPressed: _saveDraft,
                ),
                const SizedBox(width: 12),
                GgumButton(
                  width: 120,
                  text: widget.existingEntry != null ? "UPDATE" : "POST!",
                  onPressed: _processAndSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
