// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/theme.dart';
import 'features/diary/domain/diary_entry.dart';
import 'features/diary/application/diary_providers.dart';
import 'app/router.dart'; // ✅ 방금 routerProvider가 있는 파일

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(DiaryEntryAdapter());
  // Hive 데이터가 깨졌을 때 복구하도록 한 번 더 시도
  Box<DiaryEntry> box;
  try {
    box = await Hive.openBox<DiaryEntry>('diaries');
  } catch (_) {
    await Hive.deleteBoxFromDisk('diaries');
    box = await Hive.openBox<DiaryEntry>('diaries');
  }

  runApp(
    ProviderScope(
      overrides: [
        diaryBoxProvider.overrideWithValue(box),
      ],
      child: const MyApp(),
    ),
  );
}

// ✅ ConsumerWidget으로 바꿔서 routerProvider 쓴다
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider); // GoRouter 가져오기

    return MaterialApp.router(
      title: 'GGUM DREAM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router, // ✅ 여기!
    );
  }
}
