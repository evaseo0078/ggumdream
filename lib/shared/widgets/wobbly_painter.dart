// lib/shared/widgets/wobbly_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

// --- 1. WobblyPainter (CustomPainter) ---
/// 삐뚤빼뚤한 테두리와 배경을 그리는 CustomPainter
class WobblyPainter extends CustomPainter {
  final double strokeWidth;
  final Color strokeColor;
  final double wobbleIntensity;
  final double borderRadius;
  final bool drawFill;
  final Color fillColor;

  WobblyPainter({
    this.strokeWidth = 1.0,
    this.strokeColor = Colors.black,
    this.wobbleIntensity = 1.0, // 삐뚤거림 강도
    this.borderRadius = 8.0,
    this.drawFill = true,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final path = Path();
    final step = 10.0; // 삐뚤거림 포인트를 생성할 간격
    final random = Random(0); // 고정된 시드값으로 일관성 유지

    // 1. Fill (먼저 채우기)
    if (drawFill) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      // 삐뚤거림 없이 채움 (자연스러움을 위해)
      canvas.drawRRect(rRect, fillPaint);
    }

    // 2. Stroke (테두리 삐뚤빼뚤하게 그리기)
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 모서리부터 시작하여 Path 생성 (간소화된 삐뚤빼뚤 사각형 로직)
    path.moveTo(rRect.tlRadiusX, 0);

    // Top Edge
    for (double x = rRect.tlRadiusX;
        x < size.width - rRect.trRadiusX;
        x += step) {
      final yOffset =
          random.nextDouble() * wobbleIntensity - wobbleIntensity / 2;
      path.lineTo(x, yOffset);
    }
    path.lineTo(size.width - rRect.trRadiusX, 0);
    path.arcToPoint(Offset(size.width, rRect.trRadiusY),
        radius: rRect.trRadius);

    // Right Edge
    for (double y = rRect.trRadiusY;
        y < size.height - rRect.brRadiusY;
        y += step) {
      final xOffset =
          random.nextDouble() * wobbleIntensity - wobbleIntensity / 2;
      path.lineTo(size.width + xOffset, y);
    }
    path.lineTo(size.width, size.height - rRect.brRadiusY);
    path.arcToPoint(Offset(size.width - rRect.brRadiusX, size.height),
        radius: rRect.brRadius);

    // Bottom Edge
    for (double x = size.width - rRect.brRadiusX;
        x > rRect.blRadiusX;
        x -= step) {
      final yOffset =
          random.nextDouble() * wobbleIntensity - wobbleIntensity / 2;
      path.lineTo(x, size.height + yOffset);
    }
    path.lineTo(rRect.blRadiusX, size.height);
    path.arcToPoint(Offset(0, size.height - rRect.blRadiusY),
        radius: rRect.blRadius);

    // Left Edge
    for (double y = size.height - rRect.blRadiusY;
        y > rRect.tlRadiusY;
        y -= step) {
      final xOffset =
          random.nextDouble() * wobbleIntensity - wobbleIntensity / 2;
      path.lineTo(xOffset, y);
    }
    path.lineTo(0, rRect.tlRadiusY);
    path.arcToPoint(Offset(rRect.tlRadiusX, 0), radius: rRect.tlRadius);

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// --- 2. WobblyContainer (Helper Widget) ---
/// WobblyPainter를 사용하여 배경과 삐뚤빼뚤한 테두리를 그리는 컨테이너 대체 위젯
class WobblyContainer extends StatelessWidget {
  final Widget? child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;

  const WobblyContainer({
    super.key,
    this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black87,
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WobblyPainter(
        strokeWidth: borderWidth,
        strokeColor: borderColor,
        wobbleIntensity: 1.0,
        borderRadius: borderRadius,
        fillColor: backgroundColor,
        drawFill: true,
      ),
      child: Container(
        padding: padding,
        constraints: constraints,
        child: child,
      ),
    );
  }
}

// --- 3. WobblyLine (수평선) ---
/// 삐뚤빼뚤한 수평선을 그리는 위젯
class WobblyLine extends StatelessWidget {
  final Color color;
  final double height;
  final double thickness;

  const WobblyLine({
    super.key,
    this.color = const Color(0xFFE0E0E0),
    this.height = 1.0,
    this.thickness = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: WobblyHorizontalLinePainter(
          lineColor: color,
          thickness: thickness,
        ),
      ),
    );
  }
}

// --- 4. WobblyHorizontalLinePainter (수평선 전용) ---
/// 삐뚤빼뚤한 수평선을 그리는 CustomPainter
class WobblyHorizontalLinePainter extends CustomPainter {
  final Color lineColor;
  final double thickness;

  WobblyHorizontalLinePainter({
    required this.lineColor,
    this.thickness = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();
    const double wobbleIntensity = 0.5; // 선 삐뚤거림 강도
    const double step = 8.0; // 삐뚤거림 포인트 간격
    final random =
        Random(size.height.toInt() * 100); // Y 위치에 따라 시드를 다르게 줘서 각 줄이 다르게 보이게 함

    path.moveTo(0, size.height / 2); // 중앙 Y에서 시작

    for (double x = 0; x < size.width; x += step) {
      final yOffset =
          random.nextDouble() * wobbleIntensity - wobbleIntensity / 2;
      path.lineTo(x, size.height / 2 + yOffset);
    }
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WobblyHorizontalLinePainter oldDelegate) {
    return false;
  }
}
