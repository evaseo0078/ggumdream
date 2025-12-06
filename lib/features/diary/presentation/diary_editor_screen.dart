// lib/features/diary/presentation/diary_editor_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/ggum_button.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';

import '../application/diary_providers.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;

  const DiaryEditorScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry,
  });

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  late TextEditingController _textController;

  /// 시간이 정확히 기억 안 나는 경우
  bool _isSleepUnknown = false;

  /// 잠든 시간 / 깬 시간 (시/분만)
  TimeOfDay _sleepStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();

    final existing = widget.existingEntry;
    if (existing != null) {
      _textController = TextEditingController(text: existing.content);

      // ✅ 현재 모델은 "수면 구간"이 아니라 "수면 시간 값"만 있음
      // sleepDuration < 0 이면 unknown 처리
      _isSleepUnknown = existing.sleepDuration < 0;
    } else {
      _textController = TextEditingController();
      _isSleepUnknown = false;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ───────────────── 헬퍼들 (시간 계산) ─────────────────

  String _formatTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  DateTime _buildDateTime(DateTime baseDate, TimeOfDay tod) {
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      tod.hour,
      tod.minute,
    );
  }

  /// baseDate 기준으로 수면 시간 계산 (시간 단위)
  /// 규칙:
  ///  - end가 start보다 같거나 이르면 start를 하루 전으로 간주(자정 넘김)
  double _computeSleepHours(DateTime baseDate) {
    if (_isSleepUnknown) return -1.0;

    DateTime start = _buildDateTime(baseDate, _sleepStart);
    DateTime end = _buildDateTime(baseDate, _sleepEnd);

    if (!end.isAfter(start)) {
      start = start.subtract(const Duration(days: 1));
    }

    final minutes = end.difference(start).inMinutes;
    if (minutes <= 0) return 0.0;
    return minutes / 60.0;
  }

  /// 화면 표시용 문자열
  String _sleepLabel(DateTime baseDate) {
    final h = _computeSleepHours(baseDate);
    if (h < 0) return "Unknown";
    return "${h.toStringAsFixed(1)} Hours";
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ─────────────────────────────
  // ✅ 현재 모델에서 가능한 현실적 방어
  // ─────────────────────────────

  /// 같은 dream day(logicalDay) 안에
  /// "sleepDuration >= 0" 기록이 이미 있으면 또 막는다.
  bool _hasSleepRecordConflictForDay({
    required DateTime baseDate,
    required String currentId,
    required List<DiaryEntry> all,
    required double candidateSleepHours,
  }) {
    if (candidateSleepHours < 0) return false; // unknown이면 허용

    final candDay = _safeLogicalDay(baseDate);

    for (final e in all) {
      if (e.id == currentId) continue;
      if (e.sleepDuration < 0) continue;

      final eDay = _safeLogicalDay(e.date);
      if (_sameDay(candDay, eDay)) {
        return true;
      }
    }
    return false;
  }

  /// logicalDay()가 모델에 없을 수도 있으니 안전 래퍼
  DateTime _safeLogicalDay(DateTime date) {
    try {
      // ignore: invalid_use_of_protected_member
      // 만약 DiaryEntry에 logicalDay()가 이미 구현되어 있으면 아래가 더 정확
      // 하지만 여기선 date 기반 fallback
      return DateTime(date.year, date.month, date.day);
    } catch (_) {
      return DateTime(date.year, date.month, date.day);
    }
  }

  double _getRecordedSleepHoursForDay({
    required DateTime baseDate,
    required String currentId,
    required List<DiaryEntry> all,
  }) {
    final day = _safeLogicalDay(baseDate);
    double sum = 0;

    for (final e in all) {
      if (e.id == currentId) continue;
      if (e.sleepDuration < 0) continue;
      final eDay = _safeLogicalDay(e.date);
      if (_sameDay(day, eDay)) {
        sum += e.sleepDuration;
      }
    }
    return sum;
  }

  void _showSleepConflictSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '이미 이 날짜(꿈 하루 기준)에 수면 시간이 기록돼 있어요.\n'
          '다른 날짜를 선택하거나 "Don\'t Know"로 설정해 주세요.',
        ),
      ),
    );
  }

  // ───────────────── 저장 로직 ─────────────────

  Future<void> _saveDraft() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something first.")),
      );
      return;
    }

    final bool isEditMode = widget.existingEntry != null;
    final baseDate =
        isEditMode ? widget.existingEntry!.date : widget.selectedDate;

    final sleepHours = _computeSleepHours(baseDate);

    final draftEntry = DiaryEntry(
      id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
      date: baseDate,
      content: text,
      mood: isEditMode ? widget.existingEntry!.mood : "📝",
      sleepDuration: sleepHours,
      isDraft: true,
      isSold: isEditMode ? widget.existingEntry!.isSold : false,
      imageUrl: isEditMode ? widget.existingEntry!.imageUrl : null,
      summary: isEditMode ? widget.existingEntry!.summary : null,
      interpretation: isEditMode ? widget.existingEntry!.interpretation : null,
    );

    final allDiaries = ref.read(diaryListProvider);
    final currentId = draftEntry.id;

    // ✅ dream day 단위 수면 기록 중복 방지
    if (_hasSleepRecordConflictForDay(
      baseDate: baseDate,
      currentId: currentId,
      all: allDiaries,
      candidateSleepHours: sleepHours,
    )) {
      _showSleepConflictSnackBar();
      return;
    }

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

    // 👉 LLM 돌리기 전에 다이얼로그
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
              "Re-Analyzing Dream...",
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
        llmService.generateImage(text),
        llmService.analyzeDream(text),
      ]);

      final imageUrl = results[0] as String;
      final analysis = results[1] as Map<String, String>;

      final bool isEditMode = widget.existingEntry != null;
      final baseDate =
          isEditMode ? widget.existingEntry!.date : widget.selectedDate;

      final sleepHours = _computeSleepHours(baseDate);

      final newEntry = DiaryEntry(
        id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
        date: baseDate,
        content: text,
        imageUrl: imageUrl,
        summary: analysis['summary'],
        interpretation: analysis['interpretation'],
        mood: analysis['mood'] ?? "🌿",
        sleepDuration: sleepHours,
        isSold: isEditMode ? widget.existingEntry!.isSold : false,
        isDraft: false,
      );

      final allDiaries = ref.read(diaryListProvider);
      final currentId = newEntry.id;

      // ✅ dream day 단위 수면 기록 중복 방지
      if (_hasSleepRecordConflictForDay(
        baseDate: baseDate,
        currentId: currentId,
        all: allDiaries,
        candidateSleepHours: sleepHours,
      )) {
        if (!mounted) return;
        Navigator.pop(context);
        _showSleepConflictSnackBar();
        return;
      }

      if (isEditMode) {
        await ref.read(diaryListProvider.notifier).updateDiary(newEntry);
      } else {
        await ref.read(diaryListProvider.notifier).addDiary(newEntry);
        ref.read(userProvider.notifier).earnCoins(10);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? "Diary Updated!" : "Diary Posted! +10 coins"),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryDetailScreen(entryId: newEntry.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to analyze.")),
      );
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    final displayDate = widget.existingEntry?.date ?? widget.selectedDate;
    final dateStr = DateFormat('yyyy/MM/dd (E)').format(displayDate);

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
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6E6FA),
              Color.fromARGB(255, 168, 152, 255),
              Color.fromARGB(255, 152, 176, 255),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "How long did you sleep?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 129, 129, 129),
                ),
              ),
              const SizedBox(height: 10),

              // 수면 시간 입력 박스 (Glass + Wobbly)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: WobblyContainer(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    borderColor: Colors.white.withOpacity(0.45),
                    borderRadius: 20,
                    padding: EdgeInsets.zero,
                    child: _buildSleepCard(context, displayDate),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Write your dream (min 20 chars)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // 내용 입력
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
    );
  }

  /// 수면 입력 카드 내부 UI
  Widget _buildSleepCard(BuildContext context, DateTime baseDate) {
    final all = ref.watch(diaryListProvider);
    final currentId = widget.existingEntry?.id ?? "__new__";

    // 이미 같은 dream day에 기록된 known 수면시간(총합)
    final recordedHours = _getRecordedSleepHoursForDay(
      baseDate: baseDate,
      currentId: currentId,
      all: all,
    );

    return Column(
      children: [
        // 탭 버튼 영역
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isSleepUnknown = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isSleepUnknown
                        ? const Color.fromARGB(255, 190, 150, 255)
                            .withOpacity(0.2)
                        : const Color.fromARGB(0, 176, 149, 255),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Input Time",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: !_isSleepUnknown ? Colors.white : Colors.white70,
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
                onTap: () => setState(() => _isSleepUnknown = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isSleepUnknown
                        ? const Color.fromARGB(255, 190, 150, 255)
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
                      color: _isSleepUnknown ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 1, thickness: 1, color: Colors.white30),

        // 내용 영역
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isSleepUnknown
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Sleep time will not be recorded.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 잠든 시간
                    Row(
                      children: [
                        const Icon(Icons.nightlight_round,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Fell asleep',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final prev = _sleepStart;
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _sleepStart,
                            );
                            if (picked == null) return;

                            setState(() => _sleepStart = picked);

                            final candidate = _computeSleepHours(baseDate);
                            final conflict = _hasSleepRecordConflictForDay(
                              baseDate: baseDate,
                              currentId: currentId,
                              all: all,
                              candidateSleepHours: candidate,
                            );

                            if (conflict) {
                              setState(() => _sleepStart = prev); // 롤백
                              _showSleepConflictSnackBar();
                            }
                          },
                          child: Text(
                            _formatTime(_sleepStart),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 깬 시간
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Woke up',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final prev = _sleepEnd;
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _sleepEnd,
                            );
                            if (picked == null) return;

                            setState(() => _sleepEnd = picked);

                            final candidate = _computeSleepHours(baseDate);
                            final conflict = _hasSleepRecordConflictForDay(
                              baseDate: baseDate,
                              currentId: currentId,
                              all: all,
                              candidateSleepHours: candidate,
                            );

                            if (conflict) {
                              setState(() => _sleepEnd = prev); // 롤백
                              _showSleepConflictSnackBar();
                            }
                          },
                          child: Text(
                            _formatTime(_sleepEnd),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ 안내 문구(현재 모델 한계에 맞춘 버전)
                    if (recordedHours > 0)
                      Text(
                        "Already recorded sleep (dream-day): ${recordedHours.toStringAsFixed(1)}h",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      const Text(
                        "No sleep recorded yet for this dream-day.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // 계산된 총 수면 시간
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _sleepLabel(baseDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
