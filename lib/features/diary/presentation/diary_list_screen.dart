import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../music/presentation/sleep_mode_screen.dart';
import '../../shop/domain/shop_item.dart';
import '../application/diary_providers.dart';
import '../application/shop_provider.dart';
import '../application/user_provider.dart';
import '../domain/diary_entry.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart';

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
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
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
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontFamily: 'Stencil',
                        fontSize: 18,
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration:
                          BoxDecoration(color: Color(0xFFAABCC5), shape: BoxShape.circle),
                      selectedDecoration:
                          BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                    ),
                    eventLoader: (day) {
                      return diaryList.where((entry) => isSameDay(entry.date, day)).toList();
                    },
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
        shape: const CircleBorder(),
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
    final userState = ref.watch(userProvider);
    final shopItems = ref.watch(shopProvider);

    ShopItem? listing;
    try {
      listing = shopItems.firstWhere((item) => item.diaryId == entry.id);
    } catch (_) {
      listing = null;
    }

    final bool isSoldOut = listing?.isSold == true;

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
          border: Border.all(color: Colors.black12, width: 2),
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
                  onTap: () => ref.read(diaryListProvider.notifier).deleteDiary(entry.id),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _handleSellButtonTap(
                            context,
                            ref,
                            entry,
                            listing,
                            userState.userId,
                          ),
                          child: WobblyContainer(
                            backgroundColor:
                                entry.isSold ? Colors.orangeAccent : const Color(0xFFAABCC5),
                            borderColor: Colors.black12,
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              isSoldOut
                                  ? "Sold Out"
                                  : (entry.isSold ? "Selling" : "Sell"),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
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

  void _handleSellButtonTap(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
    ShopItem? listing,
    String userId,
  ) async {
    final isSoldOut = listing?.isSold == true;

    if (isSoldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This item is already sold and cannot be modified.")),
      );
      return;
    }

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to manage listings.")),
      );
      return;
    }

    if (entry.isSold && listing != null) {
      _showEditOptions(context, ref, entry, listing);
      return;
    }

    final myActiveItems = ref
        .read(shopProvider)
        .where((item) => item.ownerId == userId && !item.isSold)
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
      await _registerToShop(context, ref, entry, price);
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
                        onTap: () {
                          setState(() {
                            isFree = false;
                            errorText = null;
                          });
                        },
                        child: WobblyContainer(
                          backgroundColor:
                              !isFree ? const Color(0xFFAABCC5) : Colors.grey.shade200,
                          borderColor: Colors.black12,
                          borderRadius: 8,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Align(
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isFree = true;
                            controller.clear();
                            errorText = null;
                          });
                        },
                        child: WobblyContainer(
                          backgroundColor:
                              isFree ? const Color(0xFFAABCC5) : Colors.grey.shade200,
                          borderColor: Colors.black12,
                          borderRadius: 8,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Align(
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
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isFree)
                  const Text(
                    "This dream will be listed for 0 coins.",
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    setState(() => errorText = "Price must be > 0.");
                  } else if (price > 500) {
                    setState(() => errorText = "Max price is 500 coins.");
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
    ShopItem listing,
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
                  await ref.read(shopProvider.notifier).updatePrice(listing.id, newPrice);
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

  Future<void> _registerToShop(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
    int price,
  ) async {
    try {
      final userState = ref.read(userProvider);
      await ref.read(shopProvider.notifier).createListing(
            diary: entry,
            ownerId: userState.userId,
            ownerName: userState.username,
            price: price,
          );
      await ref.read(diaryListProvider.notifier).setSellStatus(entry.id, true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registered for $price coins!")),
        );
      }
    } catch (e) {
      await ref.read(diaryListProvider.notifier).setSellStatus(entry.id, false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to register item.")),
        );
      }
    }
  }

  Future<void> _cancelSale(
    BuildContext context,
    WidgetRef ref,
    DiaryEntry entry,
  ) async {
    try {
      await ref.read(shopProvider.notifier).cancelListing(entry.id);
      await ref.read(diaryListProvider.notifier).setSellStatus(entry.id, false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sale Canceled.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel sale.")),
        );
      }
    }
  }
}
