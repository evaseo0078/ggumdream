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
        const SnackBar(content: Text("그림을 먼저 그려주세요!")),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // 1. 이미지를 PNG 바이트로 변환
      final Uint8List? imageBytes = await _controller.toPngBytes();

      if (imageBytes == null) {
        throw Exception("이미지 변환 실패");
      }

      // 2. Gemini 서비스 호출
      final geminiService = ref.read(geminiServiceProvider);
      final interpretation = await geminiService.analyzeDreamSketch(imageBytes);

      if (!mounted) return;

      if (interpretation == null || interpretation.startsWith("오류")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("분석 실패: $interpretation")),
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      // 3. 결과와 함께 다이어리 작성 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditorScreen(
            selectedDate: DateTime.now(),
            initialContent: interpretation, // 해석된 텍스트 전달
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류가 발생했습니다: $e")),
      );
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA),
      appBar: AppBar(
        title: const Text("꿈 그리기",
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
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFAABCC5)),
                  SizedBox(height: 20),
                  Text("꿈을 분석하고 있어요...",
                      style: TextStyle(
                          fontFamily: 'Stencil', color: Colors.black54)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("간단하게 그려보세요",
                          style: TextStyle(color: Colors.grey)),
                      GgumButton(
                        text: "완료",
                        onPressed: _analyzeAndCreate,
                        width: 120,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
