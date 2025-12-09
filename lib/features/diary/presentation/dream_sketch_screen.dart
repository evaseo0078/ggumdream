import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:ggumdream/shared/widgets/ggum_button.dart';
import '../application/ai_provider.dart';
import 'diary_editor_screen.dart';

class DreamSketchScreen extends ConsumerStatefulWidget {
  const DreamSketchScreen({super.key});

  @override
  ConsumerState<DreamSketchScreen> createState() => _DreamSketchScreenState();
}

class _DreamSketchScreenState extends ConsumerState<DreamSketchScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _isAnalyzing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyzeAndCreate() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw something first.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final Uint8List? imageBytes = await _controller.toPngBytes();

      if (imageBytes == null) {
        throw Exception('Failed to export sketch image.');
      }

      final geminiService = ref.read(geminiServiceProvider);
      final interpretation = await geminiService.analyzeDreamSketch(imageBytes);

      if (!mounted) return;

      if (interpretation == null || interpretation.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze the sketch.')),
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditorScreen(
            selectedDate: DateTime.now(),
            initialContent: interpretation,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA), // 기본 배경색
      appBar: AppBar(
        title: const Text('Dream Sketch',
            style: TextStyle(fontFamily: 'Stencil', color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.clear(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6E6FA), // Light lavender
              Color.fromARGB(255, 233, 218, 255),
              Color.fromARGB(255, 216, 190, 255),
              Color.fromARGB(255, 213, 185, 255), // Light steel blue
            ],
          ),
        ),
        child: _isAnalyzing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFAABCC5)),
                    SizedBox(height: 20),
                    Text('Analyzing your sketch... hold on!',
                        style: TextStyle(
                            fontFamily: 'Stencil', color: Colors.black54)),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  child: Align(
    alignment: Alignment.centerLeft,
    child: Text(
      '🌙 Draw a quick sketch of your dream...',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 64, 64, 64),
      ),
    ),
  ),
),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 0, bottom: 10, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Signature(
                          controller: _controller,
                          backgroundColor: Colors.white,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 30, right: 20, left: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GgumButton(
                          text: 'Analyze',
                          onPressed: _analyzeAndCreate,
                          width: 120,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
