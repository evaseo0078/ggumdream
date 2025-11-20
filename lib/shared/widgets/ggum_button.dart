// lib/shared/widgets/ggum_button.dart

import 'package:flutter/material.dart';
import 'wobbly_painter.dart'; // WobblyContainer import를 위해 추가

class GgumButton extends StatelessWidget {
  final double? width;
  final double height;
  final String text;
  final VoidCallback onPressed;

  const GgumButton({
    super.key,
    this.width,
    this.height = 56,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // 기존 Container와 BoxDecoration을 WobblyContainer로 대체
    final button = SizedBox(
      height: height,
      width: width,
      child: WobblyContainer(
        backgroundColor: const Color(0xFFAABCC5),
        borderColor: Colors.black87,
        borderRadius: 12, // 둥근 모서리 적용
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );

    return button;
  }
}
