// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 앱 테마 및 화면 import
import 'app/theme.dart';
import 'home/home_shell.dart'; // 메인 화면 (하단 탭바)
import 'features/diary/domain/diary_entry.dart';
import 'features/diary/application/diary_providers.dart';

void main() async {
  // 1. Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hive (로컬 저장소) 초기화
  await Hive.initFlutter();

  // 3. Adapter 등록 (일기 데이터 모델 인식용)
  Hive.registerAdapter(DiaryEntryAdapter());

  // 4. 저장소 박스 열기
  final box = await Hive.openBox<DiaryEntry>('diaries');

  // 5. 앱 실행 (ProviderScope로 감싸서 상태 관리 활성화)
  runApp(
    ProviderScope(
      overrides: [
        // 저장소 Provider를 실제 Hive Box로 연결
        diaryBoxProvider.overrideWithValue(box),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GGUM DREAM',
      debugShowCheckedModeBanner: false, // 오른쪽 상단 DEBUG 띠 제거
      theme: AppTheme.theme,

      // ✅ 여기가 핵심 변경사항입니다!
      // LoginPage() 대신 HomeShell()을 바로 실행하여
      // 로그인 과정을 생략하고 메인 화면으로 진입합니다.
      home: const HomeShell(),
    );
  }
}
