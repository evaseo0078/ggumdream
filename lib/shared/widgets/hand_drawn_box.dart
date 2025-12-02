import 'package:flutter/material.dart';
import 'dart:math';

class HandDrawnBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const HandDrawnBox({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.borderWidth = 2,
    this.borderColor = Colors.black,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandDrawnBorderPainter(
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderColor: borderColor,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

class _HandDrawnBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;

  _HandDrawnBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rand = Random(size.width.toInt() + size.height.toInt());

    // 삐뚤빼뚤 효과를 위해 각 꼭짓점에 약간의 랜덤 오프셋을 줍니다.
    double offset() => rand.nextDouble() * 4 - 2;

    path.moveTo(borderRadius + offset(), offset());
    path.lineTo(size.width - borderRadius + offset(), offset());
    path.quadraticBezierTo(size.width + offset(), offset(),
        size.width + offset(), borderRadius + offset());
    path.lineTo(size.width + offset(), size.height - borderRadius + offset());
    path.quadraticBezierTo(size.width + offset(), size.height + offset(),
        size.width - borderRadius + offset(), size.height + offset());
    path.lineTo(borderRadius + offset(), size.height + offset());
    path.quadraticBezierTo(offset(), size.height + offset(), offset(),
        size.height - borderRadius + offset());
    path.lineTo(offset(), borderRadius + offset());
    path.quadraticBezierTo(
        offset(), offset(), borderRadius + offset(), offset());

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
