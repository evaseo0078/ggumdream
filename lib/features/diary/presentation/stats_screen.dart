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
    // 1) Nightmare Ratio - 기간 필터 적용
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
    // 2) Sleep Trend - "하루 총 수면" 최근 7일
    // ---------------------------
    final last7Days = _lastNDays(now, 7); // 날짜 리스트 (오래된 → 최신)

    // 날짜별 총 수면 합산
    // sleepDuration < 0 은 "모름" 취급이라 제외
    final Map<DateTime, double> sleepTotalByDay = {};

    for (final d in last7Days) {
      sleepTotalByDay[_dateOnly(d)] = 0.0;
    }

    for (final entry in diaryList) {
      if (entry.sleepDuration < 0) continue;

      final key = _dateOnly(entry.date);
      if (sleepTotalByDay.containsKey(key)) {
        sleepTotalByDay[key] = (sleepTotalByDay[key] ?? 0) + entry.sleepDuration;
      }
    }

    // 그래프용 데이터
    final dailyTotals = last7Days
        .map((d) => sleepTotalByDay[_dateOnly(d)] ?? 0.0)
        .toList();

    // 7일 평균 (✅ 0.0 제외)
    double avgSleep7 = 0;
    final nonZeroTotals = dailyTotals.where((v) => v > 0).toList();

    if (nonZeroTotals.isNotEmpty) {
      final sum = nonZeroTotals.fold<double>(0, (a, b) => a + b);
      avgSleep7 = sum / nonZeroTotals.length;
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

                            // ✅ 필터 탭
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                                _legendDot(Colors.redAccent),
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
                                color: Colors.redAccent,
                                title: nightmareCount == 0 ? '' : '$nightmareCount',
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
                                title: normalCount == 0 ? '' : '$normalCount',
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
              // 카드 2: Sleep Duration Trend
              // ============================
              _glassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sleep Duration Trend",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Last 7 days (daily total)",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 15,
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) =>
                                  FlLine(color: Colors.white24, strokeWidth: 1),
                              getDrawingVerticalLine: (value) =>
                                  FlLine(color: Colors.white24, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= last7Days.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final d = last7Days[index];
                                    return Text(
                                      "${d.month}/${d.day}",
                                      style: const TextStyle(fontSize: 10),
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
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.white24),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  dailyTotals.length,
                                  (index) => FlSpot(
                                    index.toDouble(),
                                    dailyTotals[index],
                                  ),
                                ),
                                isCurved: false,
                                color: const Color.fromARGB(255, 149, 117, 228),
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color.fromARGB(255, 192, 176, 233)
                                      .withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
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
  // Helpers: 날짜/필터
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
    // 간단 안전 버전: month 계산 후 day clamp
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

  List<DateTime> _lastNDays(DateTime now, int n) {
    final today = _dateOnly(now);
    return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
