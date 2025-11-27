// lib/shared/widgets/notebook_background.dart

import 'package:flutter/material.dart';

class NotebookBackground extends StatelessWidget {
  final Widget child;
  final double lineHeight;
  final Color lineColor;

  const NotebookBackground({
    super.key,
    required this.child,
    this.lineHeight = 40.0, // 줄 간격
    this.lineColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    // 1. Stack 대신 CustomPaint를 사용하여 배경을 그리고,
    //    SingleChildScrollView 내부에서는 제약 조건을 전달하지 않고 크기에 맞게 커지도록 합니다.
    return CustomPaint(
      // 배경 줄을 그리는 CustomPainter 지정
      painter: _NotebookLinesPainter(
        lineHeight: lineHeight,
        lineColor: lineColor,
      ),
      // 실제 콘텐츠를 담습니다.
      child: child,
    );
  }
}

// CustomPainter를 사용하여 배경 줄을 그리는 클래스 정의
class _NotebookLinesPainter extends CustomPainter {
  final double lineHeight;
  final Color lineColor;

  _NotebookLinesPainter({required this.lineHeight, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    // 현재 제약 조건(size.height) 내에서 그릴 수 있는 모든 줄을 그립니다.
    // SingleChildScrollView의 child인 경우, size.height는 콘텐츠의 실제 총 높이가 됩니다.
    for (double y = 0; y < size.height; y += lineHeight) {
      canvas.drawLine(
        Offset(0, y), 
        Offset(size.width, y),
        paint,
      );
    }
  }

  // 매번 다시 그릴 필요가 없으므로 false를 반환합니다.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}