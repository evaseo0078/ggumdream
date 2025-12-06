import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';
import '../../../shared/widgets/ggum_button.dart';
import '../application/diary_providers.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;
  // ✨ AI 해석 텍스트를 초기값으로 받기 위함
  final String? initialContent;

  const DiaryEditorScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry,
    this.initialContent,
  });

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  late TextEditingController _textController;
  double _sleepDuration = 7.0;
  bool _isSleepUnknown = false;

  @override
  void initState() {
    super.initState();
    // ⚡ 초기화 우선순위: 기존 일기 > AI 해석 결과 > 빈 값
    if (widget.existingEntry != null) {
      _textController =
          TextEditingController(text: widget.existingEntry!.content);
      if (widget.existingEntry!.sleepDuration < 0) {
        _isSleepUnknown = true;
      } else {
        _sleepDuration = widget.existingEntry!.sleepDuration;
      }
    } else if (widget.initialContent != null) {
      _textController = TextEditingController(text: widget.initialContent);
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
        const SnackBar(content: Text("내용을 입력해주세요.")),
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
      const SnackBar(content: Text("임시 저장되었습니다!")),
    );
    Navigator.pop(context);
  }

  // 기존 저장 로직 유지
  Future<void> _processAndSave() async {
    // ... (기존과 동일하거나 필요시 AI 분석 로직 추가)
    // 현재는 AI 분석 대신 단순 저장을 하거나,
    // 이미 분석된 텍스트를 저장하는 것이므로 단순 저장 로직만 있어도 됩니다.
    // 여기서는 간단히 저장만 하는 예시를 보여드립니다.

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final finalSleepDuration = _isSleepUnknown ? -1.0 : _sleepDuration;
    final bool isEditMode = widget.existingEntry != null;

    final newEntry = DiaryEntry(
      id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
      date: isEditMode ? widget.existingEntry!.date : widget.selectedDate,
      content: text,
      mood: "🌿", // AI 감정 분석 연결 필요 시 여기에 추가
      sleepDuration: finalSleepDuration,
      isSold: isEditMode ? widget.existingEntry!.isSold : false,
      isDraft: false,
    );

    if (isEditMode) {
      ref.read(diaryListProvider.notifier).updateDiary(newEntry);
    } else {
      ref.read(diaryListProvider.notifier).addDiary(newEntry);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // UI 코드는 기존 업로드해주신 파일과 동일하게 유지하면 됩니다.
    // 여기서는 핵심 로직만 표시했습니다. 기존 파일 UI를 그대로 쓰세요.
    final displayDate = widget.existingEntry?.date ?? widget.selectedDate;
    final dateStr = DateFormat('yyyy/MM/dd (E)').format(displayDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Stencil')),
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFE6E6FA),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "꿈 내용을 적거나 그림 분석 결과를 기다려주세요...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GgumButton(text: "저장", onPressed: _processAndSave, width: 100),
              ],
            )
          ],
        ),
      ),
    );
  }
}
