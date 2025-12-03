// lib/shared/widgets/ggum_button.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'wobbly_painter.dart'; // WobblyContainer import

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
        borderRadius: BorderRadius.circular(20), // 둥글둥글하게
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // 🔥 Glass blur 효과
          child: WobblyContainer(
            backgroundColor: Colors.white.withOpacity(0.25), // 🔥 반투명 유리 색
            borderColor: Colors.white.withOpacity(1.0),     // 🔥 빛 들어온 느낌
            borderRadius: 20,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}