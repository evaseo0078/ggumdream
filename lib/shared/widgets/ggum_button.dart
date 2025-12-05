// lib/shared/widgets/ggum_button.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'wobbly_painter.dart';

class GgumButton extends StatelessWidget {
  final double? width;
  final double height;
  final String text;
  // ✅ [수정] null을 받을 수 있도록 ? 추가
  final VoidCallback? onPressed;

  const GgumButton({
    super.key,
    this.width,
    this.height = 56,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 버튼 활성화 여부
    final isEnabled = onPressed != null;

    final child = Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          // 비활성화 시 글씨 흐리게
          color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );

    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: WobblyContainer(
            // 비활성화 시 배경색 흐리게
            backgroundColor: isEnabled
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.1),
            borderColor: isEnabled
                ? Colors.white.withOpacity(0.35)
                : Colors.white.withOpacity(0.1),
            borderRadius: 20,
            child: InkWell(
              onTap: onPressed, // null이면 클릭 안 됨
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
