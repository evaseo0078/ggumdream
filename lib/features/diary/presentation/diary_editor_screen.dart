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
  /// ✅ 선택한 날짜는 "기상일(=아침에 깬 날짜)" 개념으로 사용
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

  bool _isSleepUnknown = false;

  TimeOfDay _sleepStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();

    final existing = widget.existingEntry;
    if (existing != null) {
      _textController = TextEditingController(text: existing.content);

      // unknown 결정
      _isSleepUnknown = existing.sleepDuration < 0;

      // ✅ interval 있으면 UI 복원
      if (existing.sleepStartAt != null && existing.sleepEndAt != null) {
        _sleepStart = TimeOfDay(
          hour: existing.sleepStartAt!.hour,
          minute: existing.sleepStartAt!.minute,
        );
        _sleepEnd = TimeOfDay(
          hour: existing.sleepEndAt!.hour,
          minute: existing.sleepEndAt!.minute,
        );
        _isSleepUnknown = false;
      }
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

  // ───────────────── 헬퍼들 ─────────────────

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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// ✅ 저장용 "일기 날짜"는 항상 날짜-only로 고정
  ///    - 이렇게 해야 logicalDay 캘린더 붙는 기준이 흔들리지 않음
  DateTime _diaryDateForSave({required bool isEditMode}) {
    final raw = isEditMode
        ? (widget.existingEntry?.date ?? widget.selectedDate)
        : widget.selectedDate;
    return _dateOnly(raw);
  }

  /// ✅ 선택된 start/end로 "실제 interval" 만들기
  /// - baseDate는 "기상일(=선택한 날짜)"로 간주
  /// - end <= start면 start를 하루 전으로 간주 (자정 넘김)
  ({DateTime start, DateTime end}) _buildInterval(DateTime wakeDate) {
    DateTime start = _buildDateTime(wakeDate, _sleepStart);
    DateTime end = _buildDateTime(wakeDate, _sleepEnd);

    // ✅ 23:00 ~ 07:00 같은 케이스면
    //    start를 전날로 내려서 5일 23시 ~ 6일 07시 저장
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
    return "${h.toStringAsFixed(1)} Hours";
  }

  // ─────────────────
  // ✅ 기존 기록 구간 텍스트용
  // ─────────────────

  List<DiaryEntry> _entriesOfSameDreamDay(
      DateTime baseDate, List<DiaryEntry> all) {
    // dream-day 기준은 모델 logicalDay() 사용
    final dummy = DiaryEntry(
      id: "dummy",
      date: baseDate,
      content: "",
    );
    final day = dummy.logicalDay();

    return all.where((e) {
      return _sameDay(e.logicalDay(), day);
    }).toList();
  }

  String _formatInterval(DateTime s, DateTime e) {
    final f = DateFormat('HH:mm');
    return "${f.format(s)}~${f.format(e)}";
  }

  // ─────────────────
  // ✅ POST 시점 검증
  // ─────────────────

  bool _intervalOverlap(
      DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  /// ✅ 반환값이 null이면 통과, String이면 에러 메시지
  String? _validateSleepOnPost({
    required DiaryEntry candidate,
    required List<DiaryEntry> all,
  }) {
    // unknown이면 검증 스킵
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

    // ✅ 저장 기준 날짜 고정
    final diaryDate = _diaryDateForSave(isEditMode: isEditMode);

    DateTime? sAt;
    DateTime? eAt;
    double sleepHours = -1.0;

    if (!_isSleepUnknown) {
      final itv = _buildInterval(diaryDate); // ✅ diaryDate == 기상일
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

    // ✅ Draft는 검증 없이 저장
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

    final isEditMode = widget.existingEntry != null;

    // ✅ 저장 기준 날짜 고정
    final diaryDate = _diaryDateForSave(isEditMode: isEditMode);

    // ✅ POST 전 수면 값 계산
    DateTime? sAt;
    DateTime? eAt;
    double sleepHours = -1.0;

    if (!_isSleepUnknown) {
      final itv = _buildInterval(diaryDate); // ✅ 6일 23-07 → 5일23 ~ 6일07
      sAt = itv.start;
      eAt = itv.end;
      sleepHours = _durationFromInterval(sAt, eAt);
    }

    // ✅ 1) LLM 전에 "수면 검증" 먼저 수행 (POST 버튼에서만!)
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

    // 👉 2) 검증 통과했을 때만 LLM 로딩
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
        date: diaryDate, // ✅ 날짜-only 고정
        content: text,
        imageUrl: imageUrl,
        summary: analysis['summary'],
        interpretation: analysis['interpretation'],
        mood: analysis['mood'] ?? "🌿",
        sleepDuration: sleepHours,
        sleepStartAt: sAt,
        sleepEndAt: eAt,
        isSold: isEditMode ? widget.existingEntry!.isSold : false,
        isDraft: false,
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

  @override
  Widget build(BuildContext context) {
    // ✅ 표시용 날짜도 날짜-only로 안정화
    final displayDate = _dateOnly(widget.existingEntry?.date ?? widget.selectedDate);
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
              const SizedBox(height: 8),

              /// ✅ 상단 수면 카드 크기 "살짝" 줄이기
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: WobblyContainer(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    borderColor: Colors.white.withOpacity(0.45),
                    borderRadius: 20,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 200,
                      child: _buildSleepCard(context, displayDate),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "Write your dream (min 20 chars)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

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

              const SizedBox(height: 16),

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
  Widget _buildSleepCard(BuildContext context, DateTime wakeDate) {
    final all = ref.watch(diaryListProvider);
    final sameDayEntries = _entriesOfSameDreamDay(wakeDate, all)
        .where((e) => e.id != (widget.existingEntry?.id ?? ""))
        .toList();

    // ✅ 이미 기록된 구간 텍스트 생성
    final recordedIntervals = <String>[];
    double existingTotal = 0.0;

    for (final e in sameDayEntries) {
      if (e.sleepDuration > 0) {
        existingTotal += e.sleepDuration;
      }
      if (e.sleepStartAt != null && e.sleepEndAt != null) {
        recordedIntervals.add(_formatInterval(e.sleepStartAt!, e.sleepEndAt!));
      }
    }

    final remain = (24.0 - existingTotal).clamp(0.0, 24.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isSleepUnknown = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
              height: 34,
              child: VerticalDivider(color: Colors.white54),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isSleepUnknown = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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

        Padding(
          padding: const EdgeInsets.all(12.0),
          child: _isSleepUnknown
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
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
                    // ✅ 안내 텍스트
                    Text(
                      "오늘 남은 수면 가능 시간: ${remain.toStringAsFixed(1)}h",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recordedIntervals.isEmpty
                          ? "이미 기록된 구간: 없음"
                          : "이미 기록된 구간: ${recordedIntervals.join(", ")}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),

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
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _sleepStart,
                            );
                            if (picked != null) {
                              setState(() => _sleepStart = picked);
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
                    const SizedBox(height: 4),

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
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _sleepEnd,
                            );
                            if (picked != null) {
                              setState(() => _sleepEnd = picked);
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
                    const SizedBox(height: 6),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _sleepLabel(wakeDate),
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
