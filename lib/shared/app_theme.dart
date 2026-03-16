import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppTheme {
  static const Color bilibiliPink = Color(0xFFFB7299);
  static const Color bilibiliBlue = Color(0xFF00AEEC);
  static const Color background = Color(0xFF0F1012);
  static const Color surface = Color(0xFF1B1C20);
  static const Color surfaceVariant = Color(0xFF26272C);

  static String? _platformFontFamily() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'Microsoft YaHei UI';
    }
    return null;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _platformFontFamily(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: bilibiliPink,
        brightness: Brightness.dark,
        primary: bilibiliPink,
        secondary: bilibiliBlue,
        surface: surface,
        onSurface: Colors.white,
        surfaceContainer: surfaceVariant,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: _platformFontFamily(),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 14, height: 1.4),
        bodyMedium: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
