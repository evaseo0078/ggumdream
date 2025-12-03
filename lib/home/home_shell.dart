// lib/home/home_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/diary/presentation/diary_list_screen.dart';
import '../features/diary/presentation/diary_shop_screen.dart';
import '../features/login/account_screen.dart';

// ⚡ 탭 위치를 제어하는 리모컨 (전역 Provider)
// 0: Shop, 1: Home, 2: Settings(Profile)
final homeTabProvider = StateProvider<int>((ref) => 1);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 리모컨의 현재 값을 봅니다 (어떤 탭을 보여줄지)
    final selectedIndex = ref.watch(homeTabProvider);

    final List<Widget> screens = [
      const DiaryShopScreen(),
      const DiaryListScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          // 탭을 누르면 리모컨 값을 변경합니다
          onTap: (index) => ref.read(homeTabProvider.notifier).state = index,

          backgroundColor: const Color.fromARGB(255, 213, 212, 255),
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black45,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
