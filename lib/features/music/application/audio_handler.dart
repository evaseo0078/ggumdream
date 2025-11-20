// lib/features/music/application/audio_handler.dart

import 'package:just_audio/just_audio.dart';

/// 백그라운드 재생 없이 앱 내부에서만 동작하는 단순 음악 서비스
class SleepMusicService {
  final AudioPlayer _player = AudioPlayer();

  /// 수면 음악 재생 시작 (랜덤 + 반복)
  Future<void> startPlayback() async {
    try {
      // 1. asset 폴더에 있는 8개의 mp3 파일을 리스트로 만듭니다.
      // (파일명 규칙: music1.mp3 ~ music8.mp3)
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
        children: List.generate(8, (index) {
          return AudioSource.uri(
            Uri.parse('asset:///assets/music/music${index + 1}.mp3'),
          );
        }),
      );

      // 2. 플레이어 설정
      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      // 셔플(랜덤) 모드 켜기
      await _player.setShuffleModeEnabled(true);

      // 전체 반복 모드 (10분 동안 음악이 끊기지 않도록)
      await _player.setLoopMode(LoopMode.all);

      // 3. 재생 시작
      await _player.play();
    } catch (e) {
      print("Error playing sleep music: $e");
    }
  }

  /// 음악 정지
  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  /// 플레이어 리소스 해제 (화면 나갈 때 호출)
  void dispose() {
    _player.dispose();
  }
}
