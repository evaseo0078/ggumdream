// lib/app/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFAABCC5); // 버튼 등의 회색 하늘색
  static const Color backgroundColor = Color(0xFFF5F5F5); // 종이 배경색
  static const Color textColor = Colors.black87;

  // 폰트는 pubspec.yaml에 'Stencil' 계열 폰트를 추가했다고 가정합니다.
  // 예: font_family: 'GgumFont'
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      fontFamily: 'GgumFont', // 폰트 적용
      useMaterial3: true,
    );
  }

  // backward-compatible alias used by existing code
  static ThemeData get light => theme;
}
