import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart'; // signature 패키지 사용
import 'package:ggumdream/shared/widgets/ggum_button.dart';
import '../application/ai_provider.dart';
import 'diary_editor_screen.dart';

class DreamSketchScreen extends ConsumerStatefulWidget {
  const DreamSketchScreen({super.key});

  @override
  ConsumerState<DreamSketchScreen> createState() => _DreamSketchScreenState();
}

class _DreamSketchScreenState extends ConsumerState<DreamSketchScreen> {
  // 서명(그림) 컨트롤러 초기화
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3, // 펜 두께
    penColor: Colors.black, // 펜 색상
    exportBackgroundColor: Colors.white, // 내보낼 때 배경색
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
        const SnackBar(content: Text("Please draw something first!")),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // 1. 캔버스를 PNG 이미지 바이트로 변환
      final Uint8List? imageBytes = await _controller.toPngBytes();

      if (imageBytes == null) {
        throw Exception("Failed to export image");
      }

      // 2. Gemini에게 전송 및 해석 요청
      final geminiService = ref.read(geminiServiceProvider);
      final interpretation = await geminiService.analyzeDreamSketch(imageBytes);

      if (!mounted) return;

      // 3. 결과 텍스트를 가지고 에디터 화면으로 이동 (스택 교체)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditorScreen(
            selectedDate: DateTime.now(),
            initialContent: interpretation, // 생성된 해몽 텍스트 전달
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error analyzing sketch: $e")),
      );
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA), // 연한 보라색 배경
      appBar: AppBar(
        title: const Text("Draw Your Dream",
            style: TextStyle(fontFamily: 'Stencil', color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 192, 171, 255),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.clear(), // 지우기
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
                  Text("Interpreting your masterpiece...",
                      style: TextStyle(fontFamily: 'Stencil')),
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
                      const Text("Sketch simply!",
                          style: TextStyle(color: Colors.grey)),
                      GgumButton(
                        text: "DONE",
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
