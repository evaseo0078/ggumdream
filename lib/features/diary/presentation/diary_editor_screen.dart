import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/ggum_button.dart';
import '../application/diary_providers.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';
import 'dart:ui';

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
    // ⚡ 초기화 로직: 기존 일기 > AI 해석 > 빈 값 순서
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
          content:
              Text("Too short! Please write at least $minLength characters."),
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
            Text("Re-Analyzing Dream...",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.none)),
          ],
        ),
      ),
    );

    try {
      final llmService = ref.read(llmServiceProvider);

      final results = await Future.wait([
        llmService.generateImage(text),
        llmService.analyzeDream(text),
      ]);

      final imageUrl = results[0] as String;
      final analysis = results[1] as Map<String, String>;

      final finalSleepDuration = _isSleepUnknown ? -1.0 : _sleepDuration;
      final bool isEditMode = widget.existingEntry != null;

      final newEntry = DiaryEntry(
        id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
        date: isEditMode ? widget.existingEntry!.date : widget.selectedDate,
        content: text,
        imageUrl: imageUrl,
        summary: analysis['summary'],
        interpretation: analysis['interpretation'],
        mood: analysis['mood'] ?? "🌿",
        sleepDuration: finalSleepDuration,
        isSold: isEditMode ? widget.existingEntry!.isSold : false,
      );

      if (isEditMode) {
        ref.read(diaryListProvider.notifier).updateDiary(newEntry);
      } else {
        ref.read(diaryListProvider.notifier).addDiary(newEntry);
        ref.read(userProvider.notifier).earnCoins(10);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isEditMode ? "Diary Updated!" : "Diary Posted! +10 coins")),
      );

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
    final displayDate = widget.existingEntry?.date ?? widget.selectedDate;
    final dateStr = DateFormat('yyyy/MM/dd (E)').format(displayDate);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Color.fromARGB(255, 255, 255, 255)),
        title: Text(dateStr,
            style: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
                fontFamily: 'Stencil')),
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        onVerticalDragStart: (_) => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE6E6FA),
                Color.fromARGB(255, 168, 152, 255),
                Color.fromARGB(255, 152, 176, 255)
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("How long did you sleep?",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 129, 129, 129))),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: WobblyContainer(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      borderColor: Colors.white.withOpacity(0.45),
                      borderRadius: 20,
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _isSleepUnknown = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isSleepUnknown
                                          ? const Color.fromARGB(
                                                  255, 190, 150, 255)
                                              .withOpacity(0.2)
                                          : const Color.fromARGB(
                                              0, 176, 149, 255),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Input Time",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: !_isSleepUnknown
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 1,
                                height: 40,
                                child: VerticalDivider(color: Colors.white54),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _isSleepUnknown = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isSleepUnknown
                                          ? Color.fromARGB(255, 190, 150, 255)
                                              .withOpacity(0.35)
                                          : Colors.transparent,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Don't Know",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isSleepUnknown
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                              height: 1, thickness: 1, color: Colors.white30),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _isSleepUnknown
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      "Sleep duration will not be recorded.",
                                      style: TextStyle(
                                        color: Colors.white70,
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
                                          const Icon(Icons.bedtime,
                                              color: Colors.white),
                                          Text(
                                            "${_sleepDuration.toStringAsFixed(1)} Hours",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Slider(
                                        value: _sleepDuration,
                                        min: 0,
                                        max: 16,
                                        divisions: 32,
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white30,
                                        onChanged: (value) => setState(
                                            () => _sleepDuration = value),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Write your dream (min 20 chars)",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255))),
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: WobblyContainer(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        borderColor: Colors.white.withOpacity(0.5),
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color.fromARGB(255, 46, 46, 46),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Describe what happened in your dream...",
                            hintStyle: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GgumButton(
                      width: 140,
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
        ),
      ),
    );
  }
}
