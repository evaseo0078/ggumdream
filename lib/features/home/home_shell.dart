// lib/features/home/home_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../diary/diary_search_delegate.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  // === 탭 판별 ===
  int _indexFor(String location) {
    if (location.startsWith('/home/diary')) return 0;
    if (location.startsWith('/home/store')) return 1;
    return 2; // settings
  }

  String _titleFor(String location) {
    if (location.startsWith('/home/diary')) return 'Diary';
    if (location.startsWith('/home/store')) return 'Store';
    return 'Settings';
  }

  bool _showBars(String location) {
    // 예) 에디터 화면에서는 상/하단 바 숨기고 싶으면 여기서 처리
    // if (location == '/home/diary/new') return false;
    return true;
  }

  // === 탭별 leading ===
  Widget? _leadingFor(BuildContext context, int idx, String location) {
    // 예: 상세 화면일 때만 Back 버튼 보여주기
    final isDetail =
        location.startsWith('/home/diary/') && location != '/home/diary';
    if (idx == 0 && isDetail) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      );
    }
    return null;
  }

  // === 탭별 actions ===
  List<Widget> _actionsFor(BuildContext context, int idx) {
    switch (idx) {
      // Diary
      case 0:
        return [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showSearch(
              context: context,
              delegate: DiarySearchDelegate(
                onSelect: (id) {
                  context.push('/home/diary/$id');
                },
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'new':
                  context.push('/home/diary/new');
                  break;
                case 'export':
                  // TODO: export 구현
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Export…')));
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New entry')),
              PopupMenuItem(value: 'export', child: Text('Export')),
            ],
          ),
        ];

      // Store
      case 1:
        return [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Open cart'))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'restore':
                  // TODO: 복원 로직
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restore purchases…')),
                  );
                  break;
                case 'subs':
                  // TODO: 구독 관리 화면
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscriptions…')),
                  );
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'restore', child: Text('Restore purchases')),
              PopupMenuItem(value: 'subs', child: Text('Manage subscriptions')),
            ],
          ),
        ];

      // Settings
      default:
        return [
          PopupMenuButton<String>(
            tooltip: 'Account',
            position: PopupMenuPosition.under,
            onSelected: (v) {
              switch (v) {
                case 'profile':
                  context.push('/home/settings'); // 또는 /home/settings/profile
                  break;
                case 'signout':
                  // TODO: sessionProvider = null
                  context.go('/login');
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Edit profile')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 16),
              ),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _indexFor(location);
    final title = _titleFor(location);
    final show = _showBars(location);

    return Scaffold(
      appBar: show
          ? AppBar(
              centerTitle: true,
              leading: _leadingFor(context, idx, location),
              title: Text(title),
              actions: _actionsFor(context, idx),
            )
          : null,
      body: child,
      bottomNavigationBar: show
          ? NavigationBar(
              selectedIndex: idx,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/home/diary');
                    break;
                  case 1:
                    context.go('/home/store');
                    break;
                  case 2:
                    context.go('/home/settings');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.book_rounded),
                  label: 'Diary',
                ),
                NavigationDestination(
                  icon: Icon(Icons.store_rounded),
                  label: 'Store',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }
}
