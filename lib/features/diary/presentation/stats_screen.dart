// lib/features/diary/presentation/stats_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../application/diary_providers.dart';
import '../domain/diary_entry.dart';

enum NightmareRange { d30, m3, m6, all }

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  NightmareRange _range = NightmareRange.d30;

  // ✅ dream-day cutoff (Nightmare/Diary 논리용)
  static const int _cutoffHour = 18;

  // ✅ 24H axis
  static const double _minY = 0;
  static const double _maxY = 24;

  @override
  Widget build(BuildContext context) {
    final diaryList = ref.watch(diaryListProvider);

    if (diaryList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFC0ABFF),
          title: const Text(
            "Stats",
            style: TextStyle(
              fontFamily: 'Stencil',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text("No data yet. Record your dreams!"),
        ),
      );
    }

    // ---------------------------
    // 1) Nightmare Ratio - 기간 필터
    // ---------------------------
    final now = DateTime.now();
    final DateTime? start = _startForRange(now, _range);

    final filteredDreams = (start == null)
        ? diaryList
        : diaryList.where((e) => !e.date.isBefore(start)).toList();

    int nightmareCount = 0;
    int normalCount = 0;

    for (final entry in filteredDreams) {
      if (_isNightmareMood(entry.mood)) {
        nightmareCount++;
      } else {
        normalCount++;
      }
    }

    final int totalDreams = nightmareCount + normalCount;

    // ---------------------------
    // 2) Sleep Period Chart
    //    - 캘린더 날짜 기준 막대 (7일)
    // ---------------------------
    final todayKey = _dateOnly(now);
    final last7Days = _lastNDays(todayKey, 7); // 오래된 → 최신

    final intervalsByDay = _sleepIntervalsByCalendarDay(
      diaryList,
      last7Days,
    );

    // ---------------------------
    // 3) Average Sleep (7D)
    //
    // ✅ 요구 사항:
    //   - "최근 7일 중, 수면 등록된 날 기준"
    //   - 7일 23:00 ~ 8일 07:00 이면
    //     → 7일 막대에는 23~24가 보이더라도
    //       평균 계산은 8일 8h로만 카운트
    //
    //   => DiaryEntry.date (기상일) 기준으로
    //      밤 하나를 한 날짜에만 귀속
    // ---------------------------
    final durationByDreamDay = _sleepDurationByDreamDay(
      diaryList,
      last7Days,
    );

    double avgSleep7 = 0;
    final durationValues = last7Days
        .map((d) => durationByDreamDay[_dateOnly(d)] ?? 0.0)
        .where((v) => v > 0)
        .toList();

    if (durationValues.isNotEmpty) {
      final sum = durationValues.fold<double>(0, (a, b) => a + b);
      avgSleep7 = sum / durationValues.length;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0ABFF),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Stats",
          style: TextStyle(
            fontFamily: 'Stencil',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // =======================
              // 카드 1: Nightmare Ratio
              // =======================
              _glassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nightmare Ratio",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _rangeTabs(),
                            const SizedBox(height: 12),
                            Text(_rangeLabel(_range)),
                            const SizedBox(height: 6),
                            Text("Nightmares: $nightmareCount"),
                            Text("Normal dreams: $normalCount"),
                            const SizedBox(height: 8),
                            Text(
                              totalDreams == 0
                                  ? "Nightmares: 0.0%"
                                  : "Nightmares: ${(nightmareCount / totalDreams * 100).toStringAsFixed(1)}%",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Records counted: $totalDreams",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _legendDot(const Color.fromARGB(
                                    255, 94, 82, 82)),
                                const SizedBox(width: 6),
                                const Text("Nightmare (😢, 😡, 😱)"),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _legendDot(const Color(0xFFAABCC5)),
                                const SizedBox(width: 6),
                                const Text("Normal / Other"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: nightmareCount.toDouble(),
                                color:
                                    const Color.fromARGB(255, 94, 82, 82),
                                title: nightmareCount == 0
                                    ? ''
                                    : '$nightmareCount',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: normalCount.toDouble(),
                                color: const Color(0xFFAABCC5),
                                title: normalCount == 0
                                    ? ''
                                    : '$normalCount',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ============================
              // 카드 2: Sleep Period (24H)
              // ============================
              _glassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sleep Period (24H)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Last 7 days (range view)",
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240,
                        child: _buildSleepRangeChart(
                          days: last7Days,
                          intervalsByDay: intervalsByDay,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Average sleep (7D, excl. 0h): ${avgSleep7.toStringAsFixed(1)} h",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // ✅ Sleep range chart (multi-interval)
  // - 24H 축
  // - 자정 넘기는 구간은 2개로 분리해서 표시
  // - 세로 점선 제거
  // -----------------------------------------------------
  Widget _buildSleepRangeChart({
    required List<DateTime> days,
    required Map<DateTime, List<({double start, double end})>> intervalsByDay,
  }) {
    final groups = List.generate(days.length, (i) {
      final key = _dateOnly(days[i]);
      final intervals = intervalsByDay[key] ?? const [];

      if (intervals.isEmpty) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _maxY,
              width: 10,
              borderRadius: BorderRadius.circular(8),
              rodStackItems: [
                BarChartRodStackItem(_minY, _maxY, Colors.transparent),
              ],
            ),
          ],
        );
      }

      final segments = <({double start, double end})>[];

      for (final itv in intervals) {
        final s = itv.start;
        final e = itv.end;

        if (s == e) continue;

        if (e > s) {
          segments.add((
            start: s.clamp(_minY, _maxY).toDouble(),
            end: e.clamp(_minY, _maxY).toDouble(),
          ));
        } else {
          // ✅ 자정 넘김 표현
          segments.add((
            start: s.clamp(_minY, _maxY).toDouble(),
            end: _maxY,
          ));
          segments.add((
            start: _minY,
            end: e.clamp(_minY, _maxY).toDouble(),
          ));
        }
      }

      segments.sort((a, b) => a.start.compareTo(b.start));

      final stacks = <BarChartRodStackItem>[];
      double cursor = _minY;

      for (final seg in segments) {
        if (seg.end <= seg.start) continue;

        if (seg.start > cursor) {
          stacks.add(
            BarChartRodStackItem(cursor, seg.start, Colors.transparent),
          );
        }

        stacks.add(
          BarChartRodStackItem(
            seg.start,
            seg.end,
            const Color.fromARGB(255, 149, 117, 228),
          ),
        );

        cursor = seg.end;
      }

      if (cursor < _maxY) {
        stacks.add(
          BarChartRodStackItem(cursor, _maxY, Colors.transparent),
        );
      }

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: _maxY,
            width: 10,
            borderRadius: BorderRadius.circular(8),
            rodStackItems: stacks,
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        minY: _minY,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final v = value.round();
                if (v % 3 != 0) return const SizedBox.shrink();
                if (v < 0 || v > 24) return const SizedBox.shrink();

                final label = v.toString().padLeft(2, '0');
                return Text(label, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) {
                  return const SizedBox.shrink();
                }
                final d = days[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${d.month}/${d.day}",
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: groups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = days[group.x.toInt()];
              final key = _dateOnly(d);
              final intervals = intervalsByDay[key] ?? const [];

              if (intervals.isEmpty) {
                return BarTooltipItem(
                  "${d.month}/${d.day}\nNo sleep record",
                  const TextStyle(color: Colors.white),
                );
              }

              final lines = intervals.map((itv) {
                final s = _formatHourLabel(itv.start);
                final e = _formatHourLabel(itv.end);
                return "$s ~ $e";
              }).join("\n");

              return BarTooltipItem(
                "${d.month}/${d.day}\n$lines",
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // ✅ 캘린더 날짜 기준 수면 구간 집계 (그래프용)
  // -----------------------------------------------------
  Map<DateTime, List<({double start, double end})>> _sleepIntervalsByCalendarDay(
    List<DiaryEntry> entries,
    List<DateTime> days,
  ) {
    final map = <DateTime, List<({double start, double end})>>{
      for (final d in days) _dateOnly(d): <({double start, double end})>[],
    };

    for (final e in entries) {
      final sAt = e.sleepStartAt;
      final eAt = e.sleepEndAt;
      if (sAt == null || eAt == null) continue;

      final sKey = _dateOnly(sAt);
      final eKey = _dateOnly(eAt);

      final sHour = _hourOfDay(sAt);
      final eHour = _hourOfDay(eAt);

      // 같은 날짜면 그대로
      if (sKey == eKey) {
        if (map.containsKey(sKey)) {
          map[sKey]!.add((start: sHour, end: eHour));
        }
        continue;
      }

      // 자정 넘김: 2조각으로 분할
      if (map.containsKey(sKey)) {
        map[sKey]!.add((start: sHour, end: _maxY));
      }

      if (map.containsKey(eKey)) {
        map[eKey]!.add((start: _minY, end: eHour));
      }
    }

    return map;
  }

  // -----------------------------------------------------
  // ✅ 평균 계산용: DiaryEntry.date(기상일) 기준 총 수면시간
  //
  // - last7Days 안에 포함되는 기상일만 map에 포함
  // - 7일 23:00 ~ 8일 07:00 이면
  //   → diary.date 가 8일이라고 가정
  //   → 8일 key에 8시간만 기록
  // -----------------------------------------------------
  Map<DateTime, double> _sleepDurationByDreamDay(
    List<DiaryEntry> entries,
    List<DateTime> days,
  ) {
    final allowedDays = {
      for (final d in days) _dateOnly(d),
    };

    final map = <DateTime, double>{
      for (final d in allowedDays) d: 0.0,
    };

    for (final e in entries) {
      final sAt = e.sleepStartAt;
      final eAt = e.sleepEndAt;
      if (sAt == null || eAt == null) continue;

      // 기상일(다이어리 날짜) 기준
      final dreamDayKey = _dateOnly(e.date);
      if (!allowedDays.contains(dreamDayKey)) continue;

      final diffMinutes = eAt.difference(sAt).inMinutes;
      if (diffMinutes <= 0) continue;

      final hours = diffMinutes / 60.0;
      final clamped = hours.clamp(0.0, 24.0).toDouble();

      map[dreamDayKey] = (map[dreamDayKey] ?? 0.0) + clamped;
    }

    return map;
  }

  // -----------------------------------------------------
  // day helpers (calendar 기준)
  // -----------------------------------------------------
  List<DateTime> _lastNDays(DateTime todayKey, int n) {
    return List.generate(
      n,
      (i) => todayKey.subtract(Duration(days: n - 1 - i)),
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // -----------------------------------------------------
  // 시간 helpers
  // -----------------------------------------------------
  double _hourOfDay(DateTime dt) => dt.hour + dt.minute / 60.0;

  String _formatHourLabel(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  // ---------------------------
  // UI: Range Tabs
  // ---------------------------
  Widget _rangeTabs() {
    Widget tab(String label, NightmareRange value) {
      final selected = _range == value;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _range = value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color.fromARGB(255, 190, 150, 255).withOpacity(0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab("30D", NightmareRange.d30),
        const SizedBox(width: 6),
        tab("3M", NightmareRange.m3),
        const SizedBox(width: 6),
        tab("6M", NightmareRange.m6),
        const SizedBox(width: 6),
        tab("ALL", NightmareRange.all),
      ],
    );
  }

  // ---------------------------
  // Helpers: Nightmare 기간/라벨
  // ---------------------------
  DateTime? _startForRange(DateTime now, NightmareRange range) {
    switch (range) {
      case NightmareRange.d30:
        return now.subtract(const Duration(days: 30));
      case NightmareRange.m3:
        return _subtractMonths(now, 3);
      case NightmareRange.m6:
        return _subtractMonths(now, 6);
      case NightmareRange.all:
        return null;
    }
  }

  String _rangeLabel(NightmareRange range) {
    switch (range) {
      case NightmareRange.d30:
        return "Period: Last 30 days";
      case NightmareRange.m3:
        return "Period: Last 3 months";
      case NightmareRange.m6:
        return "Period: Last 6 months";
      case NightmareRange.all:
        return "Period: All time";
    }
  }

  DateTime _subtractMonths(DateTime date, int months) {
    final int year = date.year;
    final int month = date.month - months;
    int newYear = year;
    int newMonth = month;

    while (newMonth <= 0) {
      newMonth += 12;
      newYear -= 1;
    }

    final lastDay = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = date.day > lastDay ? lastDay : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  // ---------------------------
  // Nightmare 판단
  // ---------------------------
  bool _isNightmareMood(String moodEmoji) {
    const nightmareEmojis = {'😢', '😡', '😱'};
    return nightmareEmojis.contains(moodEmoji);
  }

  // ---------------------------
  // UI: Glass Card / Legend
  // ---------------------------
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
