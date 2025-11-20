// lib/features/music/presentation/sleep_mode_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _player;
  Timer? _stopTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // 상태 디버깅용 변수
  String _statusMessage = "Loading music...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initAudioAndPlay();
  }

  void _setupAnimation() {
    _animController = AnimationController(
      vsync: this,
      // ⚡ 애니메이션 속도를 조금 더 빠르게 (3초 -> 2초)
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // ⚡ 깜빡임 효과를 더 강하게 (0.3 -> 0.1)
    _fadeAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(_animController);
  }

  Future<void> _initAudioAndPlay() async {
    _player = AudioPlayer();

    try {
      // 1. 파일이 실제로 있는지 확인하기 위해 리스트 생성
      // 파일명이 music1.mp3 ~ music8.mp3 가 맞는지 꼭 확인하세요!
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
        children: List.generate(7, (index) {
          // ⚡ Asset 경로 설정
          return AudioSource.asset('assets/music/music${index + 1}.mp3');
        }),
      );

      // 2. 로딩 시작
      setState(() => _statusMessage = "Preparing playlist...");
      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      await _player.setShuffleModeEnabled(true);
      await _player.setLoopMode(LoopMode.all);

      // 3. 재생 시도
      setState(() => _statusMessage = "Playing sleep music...");
      await _player.play();

      // 4. 10분 타이머
      _stopTimer = Timer(const Duration(minutes: 10), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      // ⚡ [중요] 에러 발생 시 화면에 출력
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = "Error: $e";
        });
        print("Audio Error Log: $e"); // 콘솔에도 출력
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _stopTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => _showExitDialog(),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.nightlight_round,
                size: 100,
                color: Color(0xFF222222),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ⚡ 애니메이션 적용된 텍스트
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      "It's time to sleep",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Stencil',
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ⚡ 상태 메시지 (에러 발생 시 빨간색)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _hasError ? Colors.redAccent : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // ⚡ 재생이 안될 때 수동 재생 버튼 (브라우저 정책 대응)
                  if (!_player.playing && !_hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: () {
                          _player.play();
                          setState(() => _statusMessage = "Playing...");
                        },
                      ),
                    ),
                ],
              ),
            ),

            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Stop Music?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Do you want to stop the music and go back?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Playing"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "Stop & Exit",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
