// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diary/presentation/diary_detail_screen.dart';
import '../features/diary/presentation/diary_editor_screen.dart';
import '../features/diary/presentation/diary_list_screen.dart';
import '../features/diary/presentation/diary_setting_screen.dart';
import '../features/diary/presentation/diary_shop_screen.dart';
import '../features/login/login_page.dart';
import '../features/login/signup_page.dart';
import '../home/home_shell.dart';

/// 전역 GoRouter 제공
final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    // 앱을 실행하면 먼저 로그인 화면으로 이동
    initialLocation: '/login',

    routes: [
      // 1. 로그인
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: LoginPage()),
        routes: [
          // 1-1. 회원가입 ( /login/signup )
          GoRoute(
            path: 'signup',
            name: 'signup',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: SignupPage()),
          ),
        ],
      ),

      // 2. 홈 셸 (하단 탭바 포함 화면)  =>  '/'
      GoRoute(
        path: '/',
        name: 'home-shell',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: HomeShell()),
      ),

      // 3. 다이어리 관련 라우트 (필요하면 HomeShell 안에서 go('/diary/...') 로 사용)
      GoRoute(
        path: '/diary',
        name: 'diary-list',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: DiaryListScreen()),
        routes: [
          GoRoute(
            path: 'setting',
            name: 'diary-setting',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: DiarySettingScreen()),
          ),
          GoRoute(
            path: 'shop',
            name: 'diary-shop',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: DiaryShopScreen()),
          ),
          GoRoute(
            path: 'new',
            name: 'diary-new',
            pageBuilder: (ctx, state) => NoTransitionPage(
              child: DiaryEditorScreen(selectedDate: DateTime.now()),
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'diary-detail',
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(
                child: DiaryDetailScreen(entryId: id),
              );
            },
          ),
        ],
      ),
    ],

    errorPageBuilder: (ctx, state) => MaterialPage(
      child: Scaffold(
        body: Center(child: Text(state.error.toString())),
      ),
    ),
  ),
);
