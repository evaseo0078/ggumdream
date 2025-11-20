// lib/shared/widgets/ggum_button.dart

import 'package:flutter/material.dart';

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

    final button = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFAABCC5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );

    return button;
  }
}
