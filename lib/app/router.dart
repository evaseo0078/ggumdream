// lib/app/router.dart
//
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/diary/presentation/diary_list_screen.dart';
import '../features/diary/presentation/diary_editor_screen.dart';
import '../features/diary/presentation/diary_detail_screen.dart';
import '../features/diary/presentation/diary_setting_screen.dart';
import '../features/diary/presentation/diary_shop_screen.dart';
import '../features/login/login_page.dart';
import '../features/login/signup_page.dart';

// router provider 추가
final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    // 💡 앱의 시작 위치를 로그인 페이지로 변경하는 것이 좋습니다.
    //    (인증이 필요 없는 화면이 있다면 그곳으로 설정할 수 있습니다.)
    initialLocation: '/login', // 이제 앱을 켜면 로그인 화면이 먼저 보입니다.

    routes: [
      // 1. 로그인 (Login) 경로 추가
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (ctx, state) => const NoTransitionPage(child: LoginPage()),
        // 로그인 페이지 아래에 회원가입을 중첩 라우트로 넣을 수도 있습니다.
        routes: [
          // 2. 회원가입 (Signup) 경로 추가
          GoRoute(
            path: 'signup', // 전체 경로는 '/login/signup'이 됩니다.
            name: 'signup',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: SignupPage()),
          ),
        ],
      ),

      // 3. 기존 다이어리 (Diary) 경로 유지
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
              return NoTransitionPage(child: DiaryDetailScreen(entryId: id));
            },
          ),
        ],
      ),
    ],
    errorPageBuilder: (ctx, state) => MaterialPage(
      child: Scaffold(body: Center(child: Text(state.error.toString()))),
    ),
  ),
);
