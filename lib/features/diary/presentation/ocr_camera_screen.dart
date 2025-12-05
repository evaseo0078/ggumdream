import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../application/ocr_service.dart';

class OcrCameraScreen extends ConsumerStatefulWidget {
  const OcrCameraScreen({super.key});

  @override
  ConsumerState<OcrCameraScreen> createState() => _OcrCameraScreenState();
}

class _OcrCameraScreenState extends ConsumerState<OcrCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final TextEditingController _textController = TextEditingController();
  String? _ocrResult;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _showError('카메라 오류: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _showError('갤러리 오류: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _ocrResult = null;
    });

    try {
      final result = await _ocrService.processImageFromPath(imagePath);
      setState(() {
        _ocrResult = result;
        _textController.text = result;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR 처리 완료!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('OCR 처리 실패: $e');
    }
  }

  void _confirmAndNavigate() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('텍스트를 입력해주세요');
      return;
    }
    Navigator.pop(context, text);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OCR 이미지 처리',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Stencil')),
          backgroundColor: const Color.fromARGB(255, 192, 171, 255),
          leading: const BackButton(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE6E6FA),
                Color.fromARGB(255, 168, 152, 255),
                Color.fromARGB(255, 152, 176, 255),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
              children: [
                if (_isProcessing)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text('OCR 처리 중...',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  )
                else if (_ocrResult == null) ...[
                  const SizedBox(height: 60),
                  const Icon(Icons.document_scanner,
                      size: 80, color: Colors.white),
                  const SizedBox(height: 30),
                  const Text(
                    '이미지에서 텍스트 추출',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라로 촬영'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 152, 176, 255),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리에서 선택'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 152, 176, 255),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  const Text(
                    'OCR 결과 수정',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 15,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                        hintText: '인식된 텍스트를 수정하세요',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _ocrResult = null;
                            _textController.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 찍기'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 15),
                          backgroundColor: Colors.white70,
                          foregroundColor: const Color.fromARGB(255, 152, 176, 255),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _confirmAndNavigate,
                        icon: const Icon(Icons.check),
                        label: const Text('OK'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromARGB(255, 152, 176, 255),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
