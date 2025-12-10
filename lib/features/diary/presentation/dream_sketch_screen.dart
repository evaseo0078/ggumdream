import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import 'package:ggumdream/shared/widgets/ggum_button.dart';
import '../application/ai_provider.dart';
import '../../../services/gemini_service.dart' show GeminiQuotaExceededException; // 🔥 추가
import 'diary_editor_screen.dart';

class DreamSketchScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  
  const DreamSketchScreen({
    super.key,
    required this.selectedDate,
  });

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

  /// 🔔 쿼터 초과 안내 팝업
  Future<void> _showQuotaExceededDialog() {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('AI 분석 호출 한도 초과'),
          content: const Text(
            'AI 분석에 필요한 호출 한도를 초과했습니다.\n\n'
            '잠시 후 다시 시도해 주세요.\n'
            '문제가 계속되면 서비스 담당자에게 문의해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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

      // 🔥 여기서 GeminiQuotaExceededException 이 throw 될 수 있음
      final interpretation = await geminiService.analyzeDreamSketch(imageBytes);

      if (!mounted) return;

      if (interpretation == null || interpretation.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze the sketch.')),
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      // 성공 시 에디터 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditorScreen(
            selectedDate: widget.selectedDate,
            initialContent: interpretation,
          ),
        ),
      );
    } on GeminiQuotaExceededException {
      // 🔔 쿼터 초과 → 팝업 안내
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      await _showQuotaExceededDialog();
    } catch (e) {
      // 기타 예외 → 기존처럼 스낵바
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI 분석 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA),
      appBar: AppBar(
        title: const Text(
          'Dream Sketch',
          style: TextStyle(fontFamily: 'Stencil', color: Colors.white),
        ),
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
              Color(0xFFE6E6FA),
              Color.fromARGB(255, 233, 218, 255),
              Color.fromARGB(255, 216, 190, 255),
              Color.fromARGB(255, 213, 185, 255),
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
                    Text(
                      'Analyzing your sketch... hold on!',
                      style: TextStyle(
                        fontFamily: 'Stencil',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '🌙 Draw a quick sketch of your dream...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 64, 64, 64),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 0,
                        bottom: 10,
                        left: 16,
                        right: 16,
                      ),
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
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      right: 20,
                      left: 20,
                    ),
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
