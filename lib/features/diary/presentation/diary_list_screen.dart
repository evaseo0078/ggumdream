import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'diary_editor_screen.dart';
import 'diary_detail_screen.dart';
import '../application/diary_providers.dart';
import '../application/shop_provider.dart'; 
import '../../auth/application/user_provider.dart'; 
import '../../shop/domain/shop_item.dart'; 
import '../domain/diary_entry.dart';
import '../../music/presentation/sleep_mode_screen.dart'; 

class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  bool _isCalendarView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ✨ [설정] 최대 판매 가능 개수 (3개)
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
            // 1. 상단 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(_isCalendarView ? Icons.format_list_bulleted : Icons.calendar_month, color: Colors.black87),
                      onPressed: () {
                        setState(() {
                          _isCalendarView = !_isCalendarView;
                          if (!_isCalendarView) _selectedDay = null;
                        });
                      },
                    ),
                    const Text("My GGUM DREAM", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Stencil')),
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

            // 2. 캘린더 뷰
            if (_isCalendarView)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
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
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontFamily: 'Stencil', fontSize: 18)),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Color(0xFFAABCC5), shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                    ),
                    eventLoader: (day) => diaryList.where((entry) => isSameDay(entry.date, day)).toList(),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        final mood = (events.first as DiaryEntry).mood;
                        return Positioned(bottom: 1, child: Text(mood, style: const TextStyle(fontSize: 12)));
                      },
                    ),
                  ),
                ),
              ),

            // 3. 리스트 뷰
            displayList.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _isCalendarView && _selectedDay != null ? "No dreams on this day.\nTap + to write!" : "Let's make your\nfirst post",
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryEditorScreen(selectedDate: dateToWrite)));
        },
      ),
    );
  }

  Widget _buildDiaryCard(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    // 현재 이 일기가 상점에 등록된 상태인지 확인 (상점 데이터에서 찾기)
    final shopItems = ref.watch(shopProvider);
    
    // 상점 아이템 중 내 일기 내용과 같고, 판매자 이름이 나인 것 찾기
    ShopItem? matchingShopItem;
    try {
      matchingShopItem = shopItems.firstWhere(
        (item) => item.content == entry.content && item.ownerName == ref.read(userProvider).username,
      );
    } catch (e) {
      matchingShopItem = null;
    }

    // 판매 완료 여부 확인
    final bool isSoldOut = matchingShopItem != null && matchingShopItem.isSold;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryDetailScreen(entry: entry)));
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
                Text("${DateFormat('yyyy.MM.dd').format(entry.date)}  ${entry.mood}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  width: 80, height: 80,
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
                      Text(entry.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _handleSellButtonTap(context, ref, entry, isSoldOut),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              // ⚡ [UI 변경] 팔렸으면(Grey), 판매중(Orange), 미등록(Blue)
                              color: isSoldOut 
                                  ? Colors.grey 
                                  : (entry.isSold ? Colors.orangeAccent : const Color(0xFFAABCC5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isSoldOut 
                                ? "Sold Out" 
                                : (entry.isSold ? "Selling" : "Sell"),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), // 텍스트 흰색으로 통일
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

  // ⚡ [로직 수정] 판매 버튼 핸들러
  void _handleSellButtonTap(BuildContext context, WidgetRef ref, DiaryEntry entry, bool isSoldOut) async {
    // 1. 이미 팔린(Sold Out) 경우 -> 아무 작업도 안 함 (취소 불가)
    if (isSoldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This item is already sold and cannot be modified.")),
      );
      return;
    }

    if (entry.isSold) {
      // 2. 판매 중(Selling)인 경우 -> 옵션 팝업 (가격 변경 or 판매 취소)
      _showEditOptions(context, ref, entry);
    } else {
      // 3. 판매 등록 시도 -> 개수 제한 체크

      // 내 판매 목록 중 '판매 완료(isSold=true)'가 아닌, '판매 중(isSold=false)'인 아이템만 카운트
      final myActiveItems = ref.read(shopProvider).where(
        (item) => item.ownerName == ref.read(userProvider).username && !item.isSold // ⚡ [조건 추가] 팔린 건 제외
      ).length;

      if (myActiveItems >= _maxActiveListings) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Limit Reached! You can only have $_maxActiveListings active listings.")),
        );
        return;
      }

      // ✨ [수수료 로직 삭제됨] -> 바로 가격 입력
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
                // 수수료 안내 문구 삭제됨
                
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() { isFree = false; errorText = null; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: !isFree ? const Color(0xFFAABCC5) : Colors.grey[200], borderRadius: const BorderRadius.horizontal(left: Radius.circular(8))),
                          alignment: Alignment.center,
                          child: Text("Paid", style: TextStyle(fontWeight: FontWeight.bold, color: !isFree ? Colors.black : Colors.grey)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() { isFree = true; controller.clear(); errorText = null; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: isFree ? const Color(0xFFAABCC5) : Colors.grey[200], borderRadius: const BorderRadius.horizontal(right: Radius.circular(8))),
                          alignment: Alignment.center,
                          child: Text("Free", style: TextStyle(fontWeight: FontWeight.bold, color: isFree ? Colors.black : Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isFree)
                  const Text("Listed for 0 coins.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
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
                    onChanged: (value) { if (errorText != null) setState(() => errorText = null); },
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  if (isFree) { Navigator.pop(dialogContext, 0); return; }
                  if (controller.text.isEmpty) { setState(() => errorText = "Enter price."); return; }
                  final price = int.tryParse(controller.text);
                  if (price == null) { setState(() => errorText = "Numbers only."); }
                  else if (price <= 0) { setState(() => errorText = "Price > 0."); }
                  else if (price > 500) { setState(() => errorText = "Max 500."); }
                  else { Navigator.pop(dialogContext, price); }
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
                  ref.read(shopProvider.notifier).updatePrice(entry.content, newPrice);
                  ref.read(userProvider.notifier).updateSalePrice(entry.content, newPrice);
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

  void _registerToShop(BuildContext context, WidgetRef ref, DiaryEntry entry, int price) {
    // ✨ [수정됨] 코인 차감(수수료) 로직 제거됨
    // ref.read(userProvider.notifier).earnCoins(-_listingFee); 

    ref.read(diaryListProvider.notifier).toggleSell(entry.id);
    final newItem = ShopItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy.MM.dd').format(entry.date),
      content: entry.content,
      ownerName: ref.read(userProvider).username,
      price: price,
      summary: entry.summary,
      interpretation: entry.interpretation,
      imageUrl: entry.imageUrl,
    );
    ref.read(shopProvider.notifier).addItem(newItem);
    ref.read(userProvider.notifier).recordSale(newItem);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registered for $price coins!")));
  }

  void _cancelSale(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    ref.read(diaryListProvider.notifier).toggleSell(entry.id);
    ref.read(shopProvider.notifier).removeItemByContent(entry.content);
    ref.read(userProvider.notifier).cancelSale(entry.content);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sale Canceled.")));
  }
}