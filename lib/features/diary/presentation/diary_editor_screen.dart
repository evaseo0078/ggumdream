// lib/features/diary/presentation/diary_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/ggum_button.dart';
import '../application/diary_providers.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DiaryEditorScreen({super.key, required this.selectedDate});

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  final _textController = TextEditingController();
  double _sleepDuration = 7.0; // 기본값 7시간

  // ⚡ [추가됨] 수면 시간 모름 여부 체크
  bool _isSleepUnknown = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _processAndSave() async {
    if (_textController.text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFAABCC5)),
            SizedBox(height: 20),
            Text(
              "Analyzing Dream & Sleep...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final llmService = ref.read(llmServiceProvider);

      final results = await Future.wait([
        llmService.generateImage(_textController.text),
        llmService.analyzeDream(_textController.text),
      ]);

      final imageUrl = results[0] as String;
      final analysis = results[1] as Map<String, String>;

      // ⚡ [로직 수정] 모름(Unknown) 상태면 -1.0으로 저장
      final finalSleepDuration = _isSleepUnknown ? -1.0 : _sleepDuration;

      final newEntry = DiaryEntry(
        id: const Uuid().v4(),
        date: widget.selectedDate,
        content: _textController.text,
        imageUrl: imageUrl,
        summary: analysis['summary'],
        interpretation: analysis['interpretation'],
        mood: analysis['mood'] ?? "🌿",
        sleepDuration: finalSleepDuration,
      );

      ref.read(diaryListProvider.notifier).addDiary(newEntry);

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryDetailScreen(entryId: newEntry.id),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to analyze.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy/MM/dd (E)').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          dateStr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Stencil',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 수면 시간 입력 섹션
            const Text(
              "How long did you sleep?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 컨테이너 시작
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  // ⚡ 탭 버튼 (Input / Unknown)
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
                                topLeft: Radius.circular(11),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Input Time",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isSleepUnknown
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.black12,
                      ), // 구분선
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
                                topRight: Radius.circular(11),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Don't Know",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isSleepUnknown
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 1, thickness: 1),

                  // ⚡ 탭 상태에 따른 내용 변경
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isSleepUnknown
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "Sleep duration will not be recorded.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.bedtime,
                                    color: Colors.deepPurple,
                                  ),
                                  Text(
                                    "${_sleepDuration.toStringAsFixed(1)} Hours",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _sleepDuration,
                                min: 0,
                                max: 12,
                                divisions: 24,
                                activeColor: const Color(0xFFAABCC5),
                                inactiveColor: Colors.grey[300],
                                onChanged: (value) {
                                  setState(() {
                                    _sleepDuration = value;
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. 꿈 내용 입력
            const Text(
              "Write your dream",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
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
            Align(
              alignment: Alignment.centerRight,
              child: GgumButton(
                width: 120,
                text: "POST!",
                onPressed: _processAndSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
