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
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(_animController);
  }

  Future<void> _initAudioAndPlay() async {
    _player = AudioPlayer();

    try {
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
        children: List.generate(7, (index) {
          return AudioSource.asset('assets/music/music${index + 1}.mp3');
        }),
      );

      setState(() => _statusMessage = "Preparing playlist...");
      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      await _player.setShuffleModeEnabled(true);
      await _player.setLoopMode(LoopMode.all);

      setState(() => _statusMessage = "Playing sleep music...");
      await _player.play();

      _stopTimer = Timer(const Duration(minutes: 10), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = "Error: $e";
        });
        print("Audio Error Log: $e");
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
