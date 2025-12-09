// lib/features/diary/presentation/diary_editor_screen.dart

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/ggum_button.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';

import '../application/diary_providers.dart';
import '../application/user_provider.dart';
import 'ocr_camera_screen.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  /// ✅ 선택한 날짜는 "기상일(=아침에 깬 날짜)" 개념으로 사용
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;
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

  bool _isSleepUnknown = false;

  // ✅ 시간 입력 기반으로 전환
  late TimeOfDay _sleepStart;
  late TimeOfDay _sleepEnd;

  // ✅ Stats / List와 기준 통일용 (logical day)
  static const int _cutoffHour = 18;

  @override
  void initState() {
    super.initState();

    final e = widget.existingEntry;

    // 내용
    final initialText = e?.content ?? widget.initialContent ?? "";
    _textController = TextEditingController(text: initialText);

    // 수면 unknown 여부
    if (e != null && e.sleepDuration < 0) {
      _isSleepUnknown = true;
    }

    // ✅ 기존 entry에 시간 정보가 있으면 그걸로
    if (e?.sleepStartAt != null) {
      _sleepStart = TimeOfDay.fromDateTime(e!.sleepStartAt!);
    } else {
      _sleepStart = const TimeOfDay(hour: 23, minute: 0);
    }

    if (e?.sleepEndAt != null) {
      _sleepEnd = TimeOfDay.fromDateTime(e!.sleepEndAt!);
    } else {
      _sleepEnd = const TimeOfDay(hour: 7, minute: 0);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ───────────────── 헬퍼들 ─────────────────

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTod(TimeOfDay t) {
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

  /// ✅ 저장용 "일기 날짜"는 항상 날짜-only로 고정
  DateTime _diaryDateForSave({required bool isEditMode}) {
    final raw = isEditMode
        ? (widget.existingEntry?.date ?? widget.selectedDate)
        : widget.selectedDate;
    return _dateOnly(raw);
  }

  /// ✅ 선택된 start/end로 "실제 interval" 만들기
  /// - baseDate는 기상일로 간주
  /// - end <= start면 start를 하루 전으로 간주 (자정 넘김)
  ({DateTime start, DateTime end}) _buildInterval(DateTime wakeDate) {
    DateTime start = _buildDateTime(wakeDate, _sleepStart);
    DateTime end = _buildDateTime(wakeDate, _sleepEnd);

    if (!end.isAfter(start)) {
      start = start.subtract(const Duration(days: 1));
    }

    return (start: start, end: end);
  }

  double _durationFromInterval(DateTime start, DateTime end) {
    final mins = end.difference(start).inMinutes;
    if (mins <= 0) return 0.0;
    return mins / 60.0;
  }

  String _sleepLabel(DateTime wakeDate) {
    if (_isSleepUnknown) return "Unknown";

    final itv = _buildInterval(wakeDate);
    final h = _durationFromInterval(itv.start, itv.end);
    return "${h.toStringAsFixed(1)} Hours  (${_formatTod(_sleepStart)}-${_formatTod(_sleepEnd)})";
  }

  // ─────────────────
  // ✅ 기존 기록 같은 dream-day 묶기
  // ─────────────────

  List<DiaryEntry> _entriesOfSameDreamDay(
    DateTime baseDate,
    List<DiaryEntry> all,
  ) {
    final dummy = DiaryEntry(
      id: "dummy",
      date: baseDate,
      content: "",
    );
    final day = dummy.logicalDay(cutoffHour: _cutoffHour);

    return all.where((e) {
      return _sameDay(e.logicalDay(cutoffHour: _cutoffHour), day);
    }).toList();
  }

  bool _intervalOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  /// ✅ POST 버튼에서만 적용되는 검증
  String? _validateSleepOnPost({
    required DiaryEntry candidate,
    required List<DiaryEntry> all,
  }) {
    if (candidate.sleepDuration < 0) return null;

    final baseDate = candidate.date;
    final sameDayEntries = _entriesOfSameDreamDay(baseDate, all)
        .where((e) => e.id != candidate.id)
        .toList();

    // 1) 총합 24h 검사
    double existingTotal = 0.0;
    for (final e in sameDayEntries) {
      if (e.sleepDuration > 0) {
        existingTotal += e.sleepDuration;
      }
    }

    final newTotal = existingTotal + candidate.sleepDuration;
    if (newTotal > 24.0 + 1e-6) {
      final remain = (24.0 - existingTotal).clamp(0.0, 24.0);
      return "수면 시간이 24시간을 초과했어요.\n"
          "오늘 남은 수면 가능 시간: ${remain.toStringAsFixed(1)}h\n"
          "시간을 다시 수정해 주세요.";
    }

    // 2) 구간 겹침 검사
    if (candidate.sleepStartAt != null && candidate.sleepEndAt != null) {
      for (final e in sameDayEntries) {
        if (e.sleepStartAt == null || e.sleepEndAt == null) continue;

        if (_intervalOverlap(
          candidate.sleepStartAt!,
          candidate.sleepEndAt!,
          e.sleepStartAt!,
          e.sleepEndAt!,
        )) {
          return "이미 기록된 수면 구간과 겹쳐요.\n"
              "시간을 다시 수정해 주세요.";
        }
      }
    }

    return null;
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

    final isEditMode = widget.existingEntry != null;
    final diaryDate = _diaryDateForSave(isEditMode: isEditMode);

    DateTime? sAt;
    DateTime? eAt;
    double sleepHours = -1.0;

    if (!_isSleepUnknown) {
      final itv = _buildInterval(diaryDate);
      sAt = itv.start;
      eAt = itv.end;
      sleepHours = _durationFromInterval(sAt, eAt);
    }

    final draftEntry = DiaryEntry(
      id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
      date: diaryDate,
      content: text,
      mood: isEditMode ? widget.existingEntry!.mood : "📝",
      sleepDuration: sleepHours,
      sleepStartAt: sAt,
      sleepEndAt: eAt,
      isDraft: true,
      isSold: isEditMode ? widget.existingEntry!.isSold : false,
      imageUrl: isEditMode ? widget.existingEntry!.imageUrl : null,
      summary: isEditMode ? widget.existingEntry!.summary : null,
      interpretation: isEditMode ? widget.existingEntry!.interpretation : null,
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
          content: Text("Too short! Please write at least $minLength chars."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final isEditMode = widget.existingEntry != null;
    final diaryDate = _diaryDateForSave(isEditMode: isEditMode);

    // ✅ 수면 시간 계산
    DateTime? sAt;
    DateTime? eAt;
    double sleepHours = -1.0;

    if (!_isSleepUnknown) {
      final itv = _buildInterval(diaryDate);
      sAt = itv.start;
      eAt = itv.end;
      sleepHours = _durationFromInterval(sAt, eAt);
    }

    // ✅ POST 전 검증
    final tempEntryForValidation = DiaryEntry(
      id: isEditMode ? widget.existingEntry!.id : "temp",
      date: diaryDate,
      content: text,
      mood: isEditMode ? widget.existingEntry!.mood : "🌿",
      sleepDuration: sleepHours,
      sleepStartAt: sAt,
      sleepEndAt: eAt,
      isSold: isEditMode ? widget.existingEntry!.isSold : false,
      isDraft: false,
      imageUrl: isEditMode ? widget.existingEntry!.imageUrl : null,
      summary: isEditMode ? widget.existingEntry!.summary : null,
      interpretation: isEditMode ? widget.existingEntry!.interpretation : null,
    );

    final allDiaries = ref.read(diaryListProvider);
    final err =
        _validateSleepOnPost(candidate: tempEntryForValidation, all: allDiaries);

    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    // ✅ LLM 로딩
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

      final newEntry = DiaryEntry(
        id: isEditMode ? widget.existingEntry!.id : const Uuid().v4(),
        date: diaryDate,
        content: text,
        imageUrl: imageUrl,
        summary: analysis['summary'],
        interpretation: analysis['interpretation'],
        mood: analysis['mood'] ?? "🌿",
        sleepDuration: sleepHours,
        sleepStartAt: sAt,
        sleepEndAt: eAt,
        isDraft: false,
        isSold: isEditMode ? widget.existingEntry!.isSold : false,
      );

      if (isEditMode) {
        await ref.read(diaryListProvider.notifier).updateDiary(newEntry);
      } else {
        await ref.read(diaryListProvider.notifier).addDiary(newEntry);
        ref.read(userProvider.notifier).earnCoins(10);
      }

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

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
      Navigator.pop(context); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to analyze.")),
      );
    }
  }

  // ───────────────── UI ─────────────────

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepStart,
    );
    if (picked != null) {
      setState(() => _sleepStart = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepEnd,
    );
    if (picked != null) {
      setState(() => _sleepEnd = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayDate =
        _dateOnly(widget.existingEntry?.date ?? widget.selectedDate);
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

              // ✅ 수면 입력 카드
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
                        // 탭 버튼
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _isSleepUnknown = false),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isSleepUnknown
                                        ? const Color.fromARGB(
                                                255, 190, 150, 255)
                                            .withOpacity(0.2)
                                        : Colors.transparent,
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isSleepUnknown
                                        ? const Color.fromARGB(
                                                255, 190, 150, 255)
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
                          height: 1,
                          thickness: 1,
                          color: Colors.white30,
                        ),

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ✅ 라벨
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Icon(Icons.bedtime,
                                            color: Colors.white),
                                        Text(
                                          _sleepLabel(displayDate),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // ✅ Start/End 선택 버튼
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            onPressed: _pickStartTime,
                                            child: Text(
                                              "Start  ${_formatTod(_sleepStart)}",
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            onPressed: _pickEndTime,
                                            child: Text(
                                              "End  ${_formatTod(_sleepEnd)}",
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Write your dream (min 20 chars)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 28),
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OcrCameraScreen(),
                        ),
                      );

                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _textController.text = result;
                        });
                      }
                    },
                    tooltip: 'OCR 사진 인식',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ✅ 내용 입력 카드
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
}
