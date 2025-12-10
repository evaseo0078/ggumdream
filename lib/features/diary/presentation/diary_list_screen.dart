// lib/features/diary/presentation/diary_list_screen.dart

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';

import 'stats_screen.dart';

import '../../music/presentation/sleep_mode_screen.dart';
import '../../shop/domain/shop_item.dart';
import '../application/diary_providers.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';
import 'dream_sketch_screen.dart';

/// 뷰 모드
enum ViewMode { calendar, list, grid }

/// 공통 글라스 카드 위젯
Widget glassCard({
  required Widget child,
  double radius = 16,
  double opacity = 0.1,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2.5,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  ViewMode _viewMode = ViewMode.calendar;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final int _maxActiveListings = 3;

  // ✅ Stats / Editor와 동일 기준으로 dream-day cutoff 통일
  static const int _cutoffHour = 18;

  // ------------------------
  // ✅ 날짜 유틸
  // ------------------------
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// ✅ 캘린더/마커/필터의 "단일 진실 기준"
  /// - 1순위: sleepEndAt(기상일)
  /// - 2순위: dream logicalDay(cutoff=18)
  DateTime _calendarDayKey(DiaryEntry e) {
    if (e.sleepEndAt != null) {
      return _dateOnly(e.sleepEndAt!);
    }
    return _dateOnly(e.logicalDay(cutoffHour: _cutoffHour));
  }

  // ------------------------
  // ✅ Sleep 표시 헬퍼
  // ------------------------
  String _sleepText(DiaryEntry e) {
    if (e.sleepDuration < 0) return "Sleep: unknown";

    if (e.sleepStartAt != null && e.sleepEndAt != null) {
      final f = DateFormat('HH:mm');
      return "Sleep: ${e.sleepDuration.toStringAsFixed(1)} h "
          "(${f.format(e.sleepStartAt!)}-${f.format(e.sleepEndAt!)})";
    }

    return "Sleep: ${e.sleepDuration.toStringAsFixed(1)} h";
  }

  /// ✅ 카드 날짜 표시 기준
  /// - 캘린더 모드에서는 "캘린더 마커 기준과 동일"
  /// - 리스트/그리드는 기존 date 유지
  DateTime _displayDateForCard(DiaryEntry e) {
    if (_viewMode == ViewMode.calendar) {
      return _calendarDayKey(e);
    }
    return e.date;
  }

  @override
  Widget build(BuildContext context) {
    final diaryList = ref.watch(diaryListProvider);

    // ✅ 캘린더 모드 + 날짜 선택 시:
    // "sleepEndAt 우선" 캘린더 기준으로 필터링
    final displayList = (_viewMode == ViewMode.calendar && _selectedDay != null)
        ? diaryList
            .where((entry) => isSameDay(
                  _calendarDayKey(entry),
                  _selectedDay,
                ))
            .toList()
        : diaryList;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 255, 237, 253),
                  Color.fromARGB(255, 205, 230, 246),
                  Color.fromARGB(255, 172, 193, 242),
                  Color.fromARGB(255, 211, 202, 239),
                  Color.fromARGB(255, 137, 180, 239),
                  Color.fromARGB(255, 142, 124, 232),
                ],
                stops: [0.0, 0.3, 0.5, 0.7, 0.8, 1.0],
              ),
            ),
          ),
          // 배경 이미지 오버레이
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/diary_list_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // 상단 타이틀 & 모드 토글 & 음악 버튼
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            _viewMode == ViewMode.calendar
                                ? Icons.format_list_bulleted
                                : _viewMode == ViewMode.list
                                    ? Icons.grid_view
                                    : Icons.calendar_month,
                            color: const Color.fromARGB(221, 255, 255, 255),
                          ),
                          onPressed: () {
                            setState(() {
                              // Calendar → List → Grid → Calendar 순환
                              if (_viewMode == ViewMode.calendar) {
                                _viewMode = ViewMode.list;
                                _selectedDay = null;
                              } else if (_viewMode == ViewMode.list) {
                                _viewMode = ViewMode.grid;
                              } else {
                                _viewMode = ViewMode.calendar;
                              }
                            });
                          },
                        ),
                        const Text(
                          "My GGUM DREAM",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Stencil',
                            color: Color.fromARGB(255, 255, 255, 255),
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Color.fromARGB(98, 216, 216, 216),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/icons/music_note.png',
                            width: 32,
                            height: 32,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SleepModeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 캘린더 뷰
                if (_viewMode == ViewMode.calendar)
                  SliverToBoxAdapter(
                    child: Center(
                      child: glassCard(
                        radius: 20,
                        opacity: 0.23,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.86,
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),

                            // ✅ 이벤트 로더:
                            // "sleepEndAt 우선" 캘린더 기준으로 이벤트 매칭
                            eventLoader: (day) {
                              return diaryList
                                  .where((entry) => isSameDay(
                                        _calendarDayKey(entry),
                                        day,
                                      ))
                                  .toList();
                            },

                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                if (_selectedDay != null &&
                                    isSameDay(_selectedDay, selectedDay)) {
                                  _selectedDay = null;
                                } else {
                                  _selectedDay = selectedDay;
                                }
                                _focusedDay = focusedDay;
                              });
                            },

                            onPageChanged: (focusedDay) {
                              if (focusedDay.year < 2023) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cannot go further back in time.',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                setState(() {
                                  _focusedDay = DateTime(2023, 1, 1);
                                });
                              } else if (focusedDay.year > 2026) {
                                _showComingSoonDialog(context);
                                setState(() {
                                  _focusedDay = DateTime(2026, 12, 31);
                                });
                              } else {
                                setState(() {
                                  _focusedDay = focusedDay;
                                });
                              }
                            },

                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                fontFamily: 'Stencil',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              leftChevronPadding: EdgeInsets.zero,
                              rightChevronPadding: EdgeInsets.zero,
                            ),

                            calendarStyle: const CalendarStyle(
                              cellMargin: EdgeInsets.all(0),
                              cellPadding: EdgeInsets.all(2),
                              todayDecoration: BoxDecoration(
                                color: Color.fromARGB(255, 213, 215, 216),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Color.fromARGB(255, 183, 150, 240),
                                shape: BoxShape.circle,
                              ),
                            ),

                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekdayStyle: TextStyle(fontSize: 11),
                              weekendStyle: TextStyle(fontSize: 11),
                            ),

                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isEmpty) return null;

                                final diaryEntries =
                                    events.whereType<DiaryEntry>().toList();
                                if (diaryEntries.isEmpty) return null;

                                final moods =
                                    diaryEntries.map((e) => e.mood).toList();

                                final displayMoods = moods.take(2).toList();
                                final hasMore = moods.length > 2;

                                return Positioned(
                                  bottom: 1,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...displayMoods.map(
                                        (mood) => Text(
                                          mood,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                      if (hasMore)
                                        const Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 리스트 / 그리드 / 비어있을 때
                if (displayList.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _viewMode == ViewMode.calendar && _selectedDay != null
                            ? "No dreams on this day.\nTap + to write!"
                            : "Let's make your\nfirst post",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  )
                else if (_viewMode == ViewMode.grid)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildGridItem(context, displayList[index]);
                        },
                        childCount: displayList.length,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildDiaryCard(
                                context,
                                ref,
                                displayList[index],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                      childCount: displayList.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),

      // FABs
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 통계 버튼
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 드림 스케치 버튼
          GestureDetector(
            onTap: () {
              final dateToWrite = _selectedDay ?? DateTime.now();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DreamSketchScreen(
                    selectedDate: dateToWrite,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.brush,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 작성 버튼
          GestureDetector(
            onTap: () {
              final dateToWrite = _selectedDay ?? DateTime.now();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DiaryEditorScreen(selectedDate: dateToWrite),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------
  // 카드 / 그리드 아이템들
  // ------------------------

  Widget _buildDiaryCard(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
  ) {
    if (entry.isDraft) {
      return _buildDraftCard(context, ref, entry);
    }

    final shopItems = ref.watch(shopProvider);

    ShopItem? matchingShopItem;
    try {
      matchingShopItem = shopItems.firstWhere(
        (item) =>
            item.diaryId == entry.id &&
            item.ownerName == ref.read(userProvider).username,
      );
    } catch (_) {
      matchingShopItem = null;
    }

    final bool isSoldOut = matchingShopItem != null && matchingShopItem.isSold;
    final bool isListed = matchingShopItem != null;

    final displayDate = _displayDateForCard(entry);
    final dateText = DateFormat('yyyy.MM.dd').format(displayDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(entry: entry),
          ),
        );
      },
      child: Center(
        child: glassCard(
          radius: 14,
          opacity: 0.22,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.86,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 날짜 + 이모지 + 삭제 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$dateText  ${entry.mood}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _sleepText(entry),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _confirmDelete(context, ref, entry.id),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Color.fromARGB(255, 70, 70, 70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: entry.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                entry.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    // 내용 + 판매 버튼
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.summary ?? entry.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => _handleSellButtonTap(
                                context,
                                ref,
                                entry,
                                isSoldOut,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSoldOut
                                      ? const Color.fromARGB(255, 255, 255, 255)
                                      : (isListed
                                          ? const Color.fromRGBO(
                                              255, 209, 150, 1)
                                          : const Color.fromARGB(
                                              100, 255, 255, 255)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isSoldOut
                                      ? "Sold Out"
                                      : (isListed ? "Selling" : "Sell"),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 71, 71, 71),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDraftCard(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
  ) {
    final displayDate = _displayDateForCard(entry);
    final dateText = DateFormat('yyyy.MM.dd').format(displayDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryEditorScreen(
              selectedDate: entry.logicalDay(cutoffHour: _cutoffHour),
              existingEntry: entry,
            ),
          ),
        );
      },
      child: Center(
        child: glassCard(
          radius: 12,
          opacity: 0.20,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.86,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 날짜 + DRAFT + 삭제
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "$dateText  ${entry.mood}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "DRAFT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _confirmDelete(context, ref, entry.id),
                      child: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.content.length > 50
                      ? '${entry.content.substring(0, 50)}...'
                      : entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tap to complete and analyze",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Instagram 피드 스타일 Grid Item
  Widget _buildGridItem(BuildContext context, DiaryEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(entry: entry),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (entry.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  entry.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              )
            else
              const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 40),
              ),

            // Draft 뱃지
            if (entry.isDraft)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "DRAFT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Mood 이모지
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.mood,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------
  // 판매 관련 로직
  // ------------------------

  void _handleSellButtonTap(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
    bool isSoldOut,
  ) async {
    if (isSoldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This item is already sold and cannot be modified."),
        ),
      );
      return;
    }

    final shopItems = ref.read(shopProvider);
    ShopItem? matchingShopItem;
    try {
      matchingShopItem = shopItems.firstWhere(
        (item) =>
            item.diaryId == entry.id &&
            item.ownerName == ref.read(userProvider).username,
      );
    } catch (_) {
      matchingShopItem = null;
    }

    if (matchingShopItem != null) {
      _showEditOptions(context, ref, entry);
    } else {
      final myActiveItems = ref
          .read(shopProvider)
          .where(
            (item) =>
                item.ownerName == ref.read(userProvider).username &&
                !item.isSold,
          )
          .length;

      if (myActiveItems >= _maxActiveListings) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Limit Reached! You can only have $_maxActiveListings active listings.",
            ),
          ),
        );
        return;
      }

      final price = await _showPriceInputDialog(context);
      if (!context.mounted) return;
      if (price != null) {
        _registerToShop(context, ref, entry, price);
      }
    }
  }

  Future<int?> _showPriceInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool isFree = false;
    String? errorText;

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Set Price"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          isFree = false;
                          errorText = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isFree
                                ? const Color(0xFFAABCC5)
                                : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Paid",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !isFree ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          isFree = true;
                          controller.clear();
                          errorText = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isFree
                                ? const Color(0xFFAABCC5)
                                : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Free",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFree ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isFree)
                  const Text(
                    "Listed for 0 coins.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Amount (Max 500)",
                      suffixText: "coins",
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (isFree) {
                    Navigator.pop(dialogContext, 0);
                    return;
                  }
                  if (controller.text.isEmpty) {
                    setState(() => errorText = "Enter price.");
                    return;
                  }
                  final price = int.tryParse(controller.text);
                  if (price == null) {
                    setState(() => errorText = "Numbers only.");
                  } else if (price <= 0) {
                    setState(() => errorText = "Price > 0.");
                  } else if (price > 500) {
                    setState(() => errorText = "Max 500.");
                  } else {
                    Navigator.pop(dialogContext, price);
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditOptions(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Manage Sale"),
        content: const Text("What would you like to do?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final newPrice = await _showPriceInputDialog(context);
              if (!context.mounted) return;
              if (newPrice != null) {
                try {
                  final shopItems = ref.read(shopProvider);
                  final matchingItem = shopItems.firstWhere(
                    (item) =>
                        item.diaryId == entry.id &&
                        item.ownerName == ref.read(userProvider).username,
                  );
                  ref
                      .read(shopProvider.notifier)
                      .updatePrice(matchingItem.id, newPrice);
                  ref
                      .read(userProvider.notifier)
                      .updateSalePrice(entry.id, newPrice);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Price updated to $newPrice coins!"),
                    ),
                  );
                } catch (e) {
                  debugPrint("Error: $e");
                }
              }
            },
            child: const Text("Change Price"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _cancelSale(context, ref, entry);
            },
            child: const Text(
              "Stop Selling",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _registerToShop(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
    int price,
  ) async {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in first")),
        );
        return;
      }

      final username = ref.read(userProvider).username;

      // ✅ asia-northeast3 리전에 있는 Cloud Functions 인스턴스 사용
      final FirebaseFunctions functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast3');

      // ✅ onCall 이름 그대로
      final HttpsCallable callable =
          functions.httpsCallable('createMarketItem');

      // ✅ 서버에 마켓 아이템 생성 요청 (메타데이터 모두 포함)
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'diaryId': entry.id,
        'price': price,
        'ownerName': username,
        // 추가 메타데이터
        'content': entry.content,
        'summary': entry.summary,
        'interpretation': entry.interpretation,
        'imageUrl': entry.imageUrl,
        'date': entry.date.toIso8601String(),
      });

      final data = result.data as Map<dynamic, dynamic>;
      final String marketItemId = data['id'] as String;

      // ✅ 앱 내부 상태에도 새 ShopItem 반영
      final newItem = ShopItem(
        id: marketItemId,
        diaryId: entry.id,
        sellerUid: currentUser.uid,
        ownerName: username,
        date: entry.date,
        content: entry.content,
        price: price,
        summary: entry.summary,
        interpretation: entry.interpretation,
        imageUrl: entry.imageUrl,
        buyerUid: null,
        isSold: false,
        createdAt: DateTime.now(),
        purchasedAt: null,
      );

      // shopProvider 쪽에 addOrUpdate 같은 메서드가 있다면 사용
      ref.read(shopProvider.notifier).addOrUpdate(newItem);

      // 일기 리스트에서도 판매중 상태로
      ref.read(diaryListProvider.notifier).setSellStatus(entry.id, true);

      // 유저 정보(내 판매 목록, 통계 등) 업데이트
      ref.read(userProvider.notifier).recordSale(newItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registered for $price coins!")),
      );
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to register: ${e.code} ${e.message}"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to register: $e")),
      );
    }
  }

  void _cancelSale(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    ref.read(diaryListProvider.notifier).setSellStatus(entry.id, false);
    ref.read(shopProvider.notifier).cancelListing(entry.id);
    ref.read(userProvider.notifier).cancelSale(entry.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sale Canceled.")),
    );
  }

  // ------------------------
  // 삭제 / Coming Soon 다이얼로그
  // ------------------------

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String entryId,
  ) {
    // 판매중인 일기인지 확인
    final shopItems = ref.read(shopProvider);
    final currentUsername = ref.read(userProvider).username;

    final matching = shopItems.where(
      (item) => item.diaryId == entryId && item.ownerName == currentUsername,
    );

    bool isListed = false;
    bool isSold = false;
    if (matching.isNotEmpty) {
      final item = matching.first;
      isSold = item.isSold;
      isListed = !item.isSold;
    }

    if (isListed) {
      // 판매중인 일기는 삭제 불가
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Cannot Delete"),
            content: const Text(
              "This diary is currently listed for sale. Please cancel the sale first and try again.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    if (isSold) {
      // 이미 판매된 일기는 삭제 불가
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Cannot Delete"),
            content: const Text(
              "This diary has already been sold and cannot be deleted.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // 판매중이 아니면 삭제 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Diary"),
          content: const Text(
            "Are you sure you want to delete this diary entry?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(diaryListProvider.notifier).deleteDiary(entryId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Diary deleted.")),
                );
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        Future.delayed(const Duration(seconds: 4), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.2),
                    duration: const Duration(milliseconds: 3000),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: const Icon(
                          Icons.rocket_launch,
                          size: 80,
                          color: Colors.orange,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Coming Soon!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This feature will be available\nin the next version!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Stay tuned! ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: const Text(
                              '🌟✨',
                              style: TextStyle(fontSize: 20),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
