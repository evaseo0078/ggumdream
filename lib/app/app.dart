// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 ConsumerWidget 사용을 위해 추가
import 'package:google_fonts/google_fonts.dart';

import 'router.dart'; // routerProvider를 import합니다.
import 'theme.dart';

// 💡 StatelessWidget -> ConsumerWidget으로 변경
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  // 💡 build 함수의 인수를 (BuildContext context, WidgetRef ref)로 변경
  Widget build(BuildContext context, WidgetRef ref) {
    // routerProvider를 watch하여 GoRouter 인스턴스를 가져옵니다.
    final router = ref.watch(routerProvider);

    final baseTheme = AppTheme.light;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.notoSansTextTheme(baseTheme.textTheme),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      routerConfig: router,
    );
  }
}
