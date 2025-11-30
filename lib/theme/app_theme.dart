import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    primaryColor: const Color(0xFF6C63FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFF00F0FF),
      surface: Color(0xFF1E2129),
      onSurface: Colors.white,
    ),
    fontFamily: 'Roboto',
  );
}