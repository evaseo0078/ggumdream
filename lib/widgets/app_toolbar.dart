import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppToolbar extends StatelessWidget {
  final int currentIndex;

  const AppToolbar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/diary'); // 일기 목록(Home)
            break;
          case 1:
            context.go('/diary/setting'); // 설정(Setting)
            break;
          case 2:
            context.go('/diary/shop'); // 샵(Shop)
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'HOME'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'SETTING'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'SHOP'),
      ],
    );
  }
}
