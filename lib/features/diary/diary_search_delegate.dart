// lib/features/diary/presentation/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // flutter pub add fl_chart 필요
import '../application/diary_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 전체 일기 데이터 가져오기
    final diaryList = ref.watch(diaryListProvider);

    // 1. 데이터 가공: 악몽 vs 일반꿈 비율
    int nightmareCount = 0;
    int normalCount = 0;

    for (var entry in diaryList) {
      if (entry.mood == '👻' || entry.mood == '💧' || entry.mood == '🔥') {
        nightmareCount++;
      } else {
        normalCount++;
      }
    }
    int total = nightmareCount + normalCount;

    // 2. 데이터 가공: 최근 7개 수면 시간
    final recentEntries = diaryList.length > 7
        ? diaryList
              .sublist(0, 7)
              .reversed
              .toList() // 최신 7개 (역순 정렬해서 과거->현재)
        : diaryList.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Sleep & Dream Analytics",
          style: TextStyle(fontFamily: 'Stencil', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: diaryList.isEmpty
          ? const Center(child: Text("No data yet. Record your dreams!"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. 악몽 빈도 차트 (Pie Chart) ---
                  const Text(
                    "Nightmare Frequency",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: nightmareCount.toDouble(),
                            color: Colors.redAccent,
                            title: '$nightmareCount',
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
                            title: '$normalCount',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Colors.redAccent, "Nightmare (👻,💧)"),
                      const SizedBox(width: 20),
                      _buildLegend(const Color(0xFFAABCC5), "Normal/Good"),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- 2. 수면 시간 추이 (Line Chart) ---
                  const Text(
                    "Sleep Duration Trend",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Last 7 records",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ), // 날짜는 생략
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.black12),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(recentEntries.length, (index) {
                              return FlSpot(
                                index.toDouble(),
                                recentEntries[index].sleepDuration,
                              );
                            }),
                            isCurved: true,
                            color: Colors.deepPurple,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.deepPurple.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // 분석 코멘트
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      total > 0 && (nightmareCount / total > 0.3)
                          ? "⚠️ Warning: You are having frequent nightmares. Consider relaxing before sleep."
                          : "✅ Good: Your sleep pattern seems stable.",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
