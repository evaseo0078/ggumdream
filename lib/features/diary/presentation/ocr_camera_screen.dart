import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      _showError('camera error: $e');
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
      _showError('gallery error: $e');
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
          const SnackBar(content: Text('OCR processing complete!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('OCR processing failed: $e');
    }
  }

  void _confirmAndNavigate() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter some text');
      return;
    }
    Navigator.pop(context, text);
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: const Text('Failed to recognize text. Please try capturing again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        extendBody: true,
        appBar: AppBar(
          title: const Text('OCR Image Processing',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Stencil')),
          backgroundColor: const Color.fromARGB(255, 192, 171, 255),
          leading: const BackButton(color: Colors.white),
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
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
            child: _isProcessing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text('OCR processing...',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  )
                : _ocrResult == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.document_scanner,
                                  size: 120, color: Colors.white),
                              const SizedBox(height: 40),
                              const Text(
                                'Extract Text from Image',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 60),
                              ElevatedButton.icon(
                                onPressed: _pickImageFromCamera,
                                icon: const Icon(Icons.camera_alt, size: 28),
                                label: const Text('Capture with Camera',
                                    style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 20),
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      const Color.fromARGB(255, 152, 176, 255),
                                ),
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton.icon(
                                onPressed: _pickImageFromGallery,
                                icon: const Icon(Icons.photo_library, size: 28),
                                label: const Text('Select from Gallery',
                                    style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 20),
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      const Color.fromARGB(255, 152, 176, 255),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'Edit OCR Result',
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
                                  hintText: 'Edit recognized text',
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
                                  label: const Text('Retake'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 25, vertical: 15),
                                    backgroundColor: Colors.white70,
                                    foregroundColor: const Color.fromARGB(
                                        255, 152, 176, 255),
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
                                    foregroundColor: const Color.fromARGB(
                                        255, 152, 176, 255),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
