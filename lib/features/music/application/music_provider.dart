// lib/features/music/application/music_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_handler.dart';
// SleepMusicService 싱글톤 제공 — 기본적으로 간단한 구현을 반환하여
// 앱이 초기화 단계에서 예외 없이 동작하도록 합니다.

final audioHandlerProvider = Provider<SleepMusicService>((ref) {
  // 기본 동작: 바로 인스턴스 생성(앱 종료 시 dispose 필요하면 추가 구현)
  return SleepMusicService();
});

class MusicNotifier extends StateNotifier<bool> {
  final SleepMusicService _audioHandler;
  Timer? _sleepTimer;

  MusicNotifier(this._audioHandler) : super(false);

  // 재생 시작 (10분 타이머 포함)
  void playSleepMusic() {
    // 1. 재생
    _audioHandler.startPlayback();
    state = true; // 재생 중 상태

    // 2. 기존 타이머가 있다면 취소
    _sleepTimer?.cancel();

    // 3. 10분 후 자동 종료 타이머 시작
    _sleepTimer = Timer(const Duration(minutes: 10), () {
      stopMusic();
    });
  }

  // 음악 정지
  void stopMusic() {
    _audioHandler.stop(); // 음악 멈춤
    _sleepTimer?.cancel(); // 타이머 취소
    state = false; // 정지 상태
  }

  // 토글 기능
  void toggleMusic() {
    if (state) {
      stopMusic();
    } else {
      playSleepMusic();
    }
  }
}

final musicProvider = StateNotifierProvider<MusicNotifier, bool>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return MusicNotifier(audioHandler);
});
