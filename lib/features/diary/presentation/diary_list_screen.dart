import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../music/presentation/sleep_mode_screen.dart';
import '../../shop/domain/shop_item.dart';
import '../application/diary_providers.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';


class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  bool _isCalendarView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final int _maxActiveListings = 3;

  @override
  Widget build(BuildContext context) {
    final diaryList = ref.watch(diaryListProvider);
    final displayList = (_isCalendarView && _selectedDay != null)
        ? diaryList.where((entry) => isSameDay(entry.date, _selectedDay)).toList()
        : diaryList;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE4E8),
      body: SafeArea(
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
                        _isCalendarView ? Icons.format_list_bulleted : Icons.calendar_month,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        setState(() {
                          _isCalendarView = !_isCalendarView;
                          if (!_isCalendarView) _selectedDay = null;
                        });
                      },
                    ),
                    const Text(
                      "My GGUM DREAM",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Stencil',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.music_note, color: Colors.deepPurple),
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

            if (_isCalendarView)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12, width: 4),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2025, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                      setState(() => _focusedDay = focusedDay);
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontFamily: 'Stencil',
                        fontSize: 18,
                      ),
                      leftChevronIcon: GestureDetector(
                        onTap: () {
                          final previousMonth = DateTime(_focusedDay.year, _focusedDay.month - 1);
                          if (previousMonth.isBefore(DateTime.utc(2023, 1, 1))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Only diaries from the last 3 years are saved.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            setState(() => _focusedDay = previousMonth);
                          }
                        },
                        child: const Icon(Icons.chevron_left, color: Colors.black87),
                      ),
                      rightChevronIcon: GestureDetector(
                        onTap: () {
                          final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1);
                          if (nextMonth.isAfter(DateTime.utc(2025, 12, 31))) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      size: 80,
                                      color: Color(0xFFAABCC5),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      '2026',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Stencil',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Coming Soon! ✨',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'The next version will be\nreleased in 2026.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            setState(() => _focusedDay = nextMonth);
                          }
                        },
                        child: const Icon(Icons.chevron_right, color: Colors.black87),
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Color(0xFFAABCC5), shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                    ),
                    eventLoader: (day) => diaryList.where((entry) => isSameDay(entry.date, day)).toList(),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        final mood = (events.first as DiaryEntry).mood;
                        return Positioned(
                          bottom: 1,
                          child: Text(mood, style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),
                  ),
                ),
              ),

            displayList.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _isCalendarView && _selectedDay != null 
                            ? "No dreams on this day.\nTap + to write!" 
                            : "Let's make your\nfirst post",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDiaryCard(context, ref, displayList[index]),
                        );
                      },
                      childCount: displayList.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFAABCC5),
        child: const Icon(Icons.edit, color: Colors.black87),
        onPressed: () {
          final dateToWrite = _selectedDay ?? DateTime.now();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryEditorScreen(selectedDate: dateToWrite),
            ),
          );
        },
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black12),
        ),
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
                  child: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: entry.imageUrl != null
                      ? Image.network(entry.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 8),
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
                                  ? Colors.grey
                                  : (isListed ? Colors.orangeAccent : const Color(0xFFAABCC5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isSoldOut 
                                  ? "Sold Out" 
                                  : (isListed ? "Selling" : "Sell"),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange, width: 2),
        ),
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
            const SizedBox(height: 8),
            const Text(
              "Tap to complete and analyze",
              style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
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
}
