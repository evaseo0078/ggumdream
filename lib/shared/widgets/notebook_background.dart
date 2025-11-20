// lib/shared/widgets/notebook_background.dart

import 'package:flutter/material.dart';
import 'package:ggumdream/shared/widgets/wobbly_painter.dart'; // FIX: 패키지 경로로 변경

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
        // 1. 배경에 삐뚤빼뚤한 가로줄 그리기
        LayoutBuilder(
          builder: (context, constraints) {
            // LineHeight 40을 기준으로 계산
            final int lineCount = (constraints.maxHeight / lineHeight).ceil();

            return Column(
              children: List.generate(lineCount, (index) {
                return Column(
                  children: [
                    // --- Wobbly Line ---
                    SizedBox(
                      height: lineHeight - 1.0, // 선 두께만큼 빼고 공간 확보
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: WobblyLine(
                          thickness: 1.0,
                          color: lineColor,
                        ),
                      ),
                    ),
                    // ------------------
                    const SizedBox(
                        height:
                            1.0), // 실제 선의 두께를 위해 1.0 공간 사용 (WobblyLine에서 처리)
                  ],
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
