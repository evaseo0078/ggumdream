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
    return Stack(
      children: [
        // 1. 배경에 가로줄 그리기
        LayoutBuilder(
          builder: (context, constraints) {
            final int lineCount = (constraints.maxHeight / lineHeight).ceil();
            return Column(
              children: List.generate(lineCount, (index) {
                return Container(
                  height: lineHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: lineColor, width: 1.0),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        // 2. 실제 콘텐츠
        child,
      ],
    );
  }
}
