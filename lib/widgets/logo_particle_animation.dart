import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class LogoParticleAnimation extends StatefulWidget {
  final String logoAssetPath;
  final double width;
  final double height;

  /// 원하는 위치로 이동
  final double offsetX;
  final double offsetY;

  final double logoScale;

  const LogoParticleAnimation({
    super.key,
    required this.logoAssetPath,
    this.width = 200,
    this.height = 100,
    this.offsetX = 0,
    this.offsetY = 0,
    this.logoScale = 1.0,  // 기본값 1.0
  });


  @override
  State<LogoParticleAnimation> createState() => _LogoParticleAnimationState();
}

class _LogoParticleAnimationState extends State<LogoParticleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  ui.Image? finalImage;
  List<Offset> logoPixels = [];
  List<Particle> particles = [];

  int logoW = 0;
  int logoH = 0;

  // 최종 이미지 전환용
  bool showFinalImage = false;
  double imageOpacity = 0.0;

  double scale = 100.0;// 로고 scaling factor

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener(_handleAnimationEnd);

    _loadLogoAndExtractPixels();
  }

  // 애니메이션 끝나면 이미지로 전환
  void _handleAnimationEnd(AnimationStatus status) async {
    if (status == AnimationStatus.completed) {
      setState(() => showFinalImage = true);

      // 천천히 로고 나타나는 fade-in
      for (double i = 0; i <= 1; i += 0.02) {
        await Future.delayed(const Duration(milliseconds: 16));
        setState(() => imageOpacity = i);
      }
    }
  }

  Future<void> _loadLogoAndExtractPixels() async {
    final data =
        await DefaultAssetBundle.of(context).load(widget.logoAssetPath);

    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    finalImage = image;
    logoW = image.width;
    logoH = image.height;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = byteData!.buffer.asUint8List();

    // 로고 픽셀 수집 (흰색 픽셀만)
    for (int y = 0; y < logoH; y += 3) {
      for (int x = 0; x < logoW; x += 3) {
        int index = (y * logoW + x) * 4;

        int r = pixels[index];
        int g = pixels[index + 1];
        int b = pixels[index + 2];
        int a = pixels[index + 3];

        if (a > 200 && r > 200 && g > 200 && b > 200) {
          logoPixels.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    final rnd = Random();

    // 로고 크기를 지정된 width/height에 맞춰서 스케일링
    double scaleX = widget.width / logoW;
    double scaleY = widget.height / logoH;
    scale = min(scaleX, scaleY) * widget.logoScale;

    for (final offset in logoPixels) {
      // 로고 중심 기준 좌표 + 스케일 적용
      final centered = Offset(
        (offset.dx - logoW / 2) * scale,
        (offset.dy - logoH / 2) * scale,
      );

      particles.add(
        Particle(
          x: rnd.nextDouble() * widget.width - widget.width / 2,
          y: rnd.nextDouble() * widget.height - widget.height / 2,
          targetX: centered.dx,
          targetY: centered.dy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(
        particles: particles,
        t: _controller.value,
        offsetX: widget.offsetX,
        offsetY: widget.offsetY,
        showFinalImage: showFinalImage,
        finalImage: finalImage,
        imageOpacity: imageOpacity,
        scale: scale,
        width: widget.width,
        height: widget.height,
      ),
      size: Size(widget.width, widget.height),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 파티클 데이터
class Particle {
  double x, y;
  final double targetX, targetY;

  Particle({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
  });

  Offset animate(double t) {
    double curve = Curves.easeOut.transform(t);

    return Offset(
      lerpDouble(x, targetX, curve)!,
      lerpDouble(y, targetY, curve)!,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double t;
  final double offsetX;
  final double offsetY;

  final bool showFinalImage;
  final ui.Image? finalImage;
  final double imageOpacity;
  final double scale;

  final double width;
  final double height;

  ParticlePainter({
    required this.particles,
    required this.t,
    required this.offsetX,
    required this.offsetY,
    required this.showFinalImage,
    required this.finalImage,
    required this.imageOpacity,
    required this.scale,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 중심으로 이동 + 오프셋 적용
    canvas.translate(
      size.width / 2 + offsetX,
      size.height / 2 + offsetY,
    );

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 별가루
    if (!showFinalImage) {
      for (final p in particles) {
        final pos = p.animate(t);
        canvas.drawPoints(ui.PointMode.points, [pos], paint);
      }
    }

    // 최종 로고 이미지
    if (showFinalImage && finalImage != null) {
      final paintImageLogo = Paint()
        ..color = Colors.white.withOpacity(imageOpacity);

      final rect = Rect.fromCenter(
        center: Offset(0, 0),
        width: finalImage!.width * scale,
        height: finalImage!.height * scale,
      );

      canvas.drawImageRect(
        finalImage!,
        Rect.fromLTWH(
            0, 0, finalImage!.width.toDouble(), finalImage!.height.toDouble()),
        rect,
        paintImageLogo,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
