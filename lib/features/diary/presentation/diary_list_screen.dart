import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'stats_screen.dart';

import '../../music/presentation/sleep_mode_screen.dart';
import '../../shop/domain/shop_item.dart';
import '../application/diary_providers.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';

import 'dart:ui';

// ⚡ 뷰 모드 enum 추가
enum ViewMode { calendar, list, grid }

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
  ViewMode _viewMode = ViewMode.calendar; // ⚡ enum 사용
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final int _maxActiveListings = 3;

  @override
  Widget build(BuildContext context) {
    final diaryList = ref.watch(diaryListProvider);
    final displayList = (_viewMode == ViewMode.calendar && _selectedDay != null)
        ? diaryList.where((entry) => isSameDay(entry.date, _selectedDay)).toList()
        : diaryList;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 255, 237, 253),
                  Color.fromARGB(255, 205,230,246),
                  Color.fromARGB(255, 172,193,242),
                  Color.fromARGB(255, 211,202,239),
                  Color.fromARGB(255, 137,180,239),
                  Color.fromARGB(255, 142, 124, 232),
                ],
                stops: [0.0, 0.3, 0.5, 0.7, 0.8, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.4, // Adjusted transparency
              child: Image.asset(
                'assets/images/diary_list_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
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
                              MaterialPageRoute(builder: (context) => const SleepModeScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_viewMode == ViewMode.calendar)
                  SliverToBoxAdapter(
  child: Center(
    child: glassCard(
      radius: 20,
      opacity: 0.23,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

          // ⚡ eventLoader 추가: 해당 날짜의 일기들을 반환
          eventLoader: (day) {
            return diaryList.where((entry) => isSameDay(entry.date, day)).toList();
          },

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              if (_selectedDay != null && isSameDay(_selectedDay, selectedDay)) {
                _selectedDay = null;
              } else {
                _selectedDay = selectedDay;
              }
              _focusedDay = focusedDay;
            });
          },

          onPageChanged: (focusedDay) {
            // 연도 제한 체크
            if (focusedDay.year < 2023) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot go further back in time.'),
                  duration: Duration(seconds: 3),
                ),
              );
              // 2023년 1월로 되돌리기
              setState(() {
                _focusedDay = DateTime(2023, 1, 1);
              });
            } else if (focusedDay.year > 2026) {
              _showComingSoonDialog(context);
              // 2026년 12월로 되돌리기
              setState(() {
                _focusedDay = DateTime(2026, 12, 31);
              });
            } else {
              // 허용된 범위 내에서만 업데이트
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
              
              // ⚡ 해당 날짜의 모든 일기들의 mood 수집
              final diaryEntries = events.cast<DiaryEntry>();
              final moods = diaryEntries.map((e) => e.mood).toList();
              
              // 최대 2개까지 표시, 그 이상이면 + 추가
              final displayMoods = moods.take(2).toList();
              final hasMore = moods.length > 2;
              
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...displayMoods.map((mood) => Text(
                      mood,
                      style: const TextStyle(fontSize: 10),
                    )),
                    if (hasMore)
                      const Text(
                        '+',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
const SliverToBoxAdapter(
  child: SizedBox(height: 10),  // ← 여기서 원하는 높이로 조절
),

                displayList.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(
                            _viewMode == ViewMode.calendar && _selectedDay != null
                                ? "No dreams on this day.\nTap + to write!"
                                : "Let's make your\nfirst post",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ),
                      )
                    : _viewMode == ViewMode.grid
                        ? SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, // ⚡ 가로 3개
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio: 1, // 정사각형
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildGridItem(context, displayList[index]);
                                },
                                childCount: displayList.length,
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: _buildDiaryCard(context, ref, displayList[index]),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 통계 버튼
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatsScreen(),
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
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
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
                  builder: (context) => DiaryEditorScreen(selectedDate: dateToWrite),
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

  Widget _buildDiaryCard(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    if (entry.isDraft) {
      return _buildDraftCard(context, ref, entry);
    }

    final shopItems = ref.watch(shopProvider);
    
    ShopItem? matchingShopItem;
    try {
      matchingShopItem = shopItems.firstWhere(
        (item) => item.diaryId == entry.id && item.ownerName == ref.read(userProvider).username,
      );
    } catch (e) {
      matchingShopItem = null;
    }

    final bool isSoldOut = matchingShopItem != null && matchingShopItem.isSold;
    final bool isListed = matchingShopItem != null;

    return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiaryDetailScreen(entry: entry)),
    );
  },

  child: Center( // 🔥 가운데 정렬
    child: glassCard(
      radius: 14,
      opacity: 0.22,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86, // 🔥 카드 폭 줄이기
        margin: const EdgeInsets.only(bottom: 14),       // 🔥 아래 간격 줄이기
        padding: const EdgeInsets.all(10),               // 🔥 패딩 줄이기
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${DateFormat('yyyy.MM.dd').format(entry.date)}  ${entry.mood}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () => _confirmDelete(context, ref, entry.id),
                  child: const Icon(Icons.delete_outline, size: 20, color: Color.fromARGB(255, 70, 70, 70)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72, // 🔥 조금 더 작게
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12), // Rounded corners for images
                  ),
                  child: entry.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12), // Match the container's rounded corners
                          child: Image.network(entry.imageUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 10),
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
                          onTap: () => _handleSellButtonTap(context, ref, entry, isSoldOut),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSoldOut
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : (isListed ? const Color.fromRGBO(255, 209, 150, 1) : const Color.fromARGB(100, 255, 255, 255)),
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

  Widget _buildDraftCard(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorScreen(
          selectedDate: entry.date,
          existingEntry: entry,
        ),
      ),
    );
  },

  child: Center( // 🔥 가운데 정렬
    child: glassCard(
      radius: 12,
      opacity: 0.20,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86, // 🔥 통일감
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "${DateFormat('yyyy.MM.dd').format(entry.date)}  ${entry.mood}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap to complete and analyze",
              style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    ),
  ),
);

  }

  /// ⚡ Instagram 피드 스타일 Grid Item
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
            // 이미지 표시
            if (entry.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  entry.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              // 이미지가 없는 경우 기본 아이콘
              const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            
            // Draft 뱃지 (draft인 경우)
            if (entry.isDraft)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            
            // Mood 이모지 (하단 왼쪽)
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

  void _handleSellButtonTap(BuildContext context, WidgetRef ref, DiaryEntry entry, bool isSoldOut) async {
    if (isSoldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This item is already sold and cannot be modified.")),
      );
      return;
    }

    final shopItems = ref.read(shopProvider);
    ShopItem? matchingShopItem;
    try {
      matchingShopItem = shopItems.firstWhere(
        (item) => item.diaryId == entry.id && item.ownerName == ref.read(userProvider).username,
      );
    } catch (e) {
      matchingShopItem = null;
    }

    if (matchingShopItem != null) {
      _showEditOptions(context, ref, entry);
    } else {
      final myActiveItems = ref.read(shopProvider).where(
        (item) => item.ownerName == ref.read(userProvider).username && !item.isSold
      ).length;

      if (myActiveItems >= _maxActiveListings) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Limit Reached! You can only have $_maxActiveListings active listings.")),
        );
        return;
      }

      int? price = await _showPriceInputDialog(context);
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
                            color: !isFree ? const Color(0xFFAABCC5) : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
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
                            color: isFree ? const Color(0xFFAABCC5) : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
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
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (errorText != null) setState(() => errorText = null);
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

  void _showEditOptions(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Manage Sale"),
        content: const Text("What would you like to do?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              int? newPrice = await _showPriceInputDialog(context);
              if (!context.mounted) return;
              if (newPrice != null) {
                try {
                  final shopItems = ref.read(shopProvider);
                  final matchingItem = shopItems.firstWhere(
                    (item) => item.diaryId == entry.id && item.ownerName == ref.read(userProvider).username,
                  );
                  ref.read(shopProvider.notifier).updatePrice(matchingItem.id, newPrice);
                  ref.read(userProvider.notifier).updateSalePrice(entry.id, newPrice);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Price updated to $newPrice coins!")),
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
            child: const Text("Stop Selling", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _registerToShop(BuildContext context, WidgetRef ref, DiaryEntry entry, int price) async {
    try {
      // Firestore에 등록하고 생성된 ShopItem을 받아옴
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in first")),
        );
        return;
      }
      
      final newItem = await ref.read(shopProvider.notifier).createListing(
        diary: entry,
        ownerId: currentUser.uid, // Firebase UID 직접 사용
        ownerName: ref.read(userProvider).username,
        price: price,
      );
      
      // 일기 상태 업데이트
      ref.read(diaryListProvider.notifier).setSellStatus(entry.id, true);
      
      // 사용자 판매 이력에 추가
      ref.read(userProvider.notifier).recordSale(newItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registered for $price coins!")),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, String entryId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Diary"),
          content: const Text("Are you sure you want to delete this diary entry?"),
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
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
        // 4초 후 자동으로 닫기
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
                  // 애니메이션 로켓 아이콘
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
                  
                  // 메인 메시지
                  const Text(
                    'Coming Soon!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 서브 메시지
                  const Text(
                    'This feature will be available\nin the next version!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 기대 메시지
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
