import 'package:flutter/material.dart';

/// Central color palette and theme for the JARVIS app.
/// Everything is tuned for a dark, futuristic, Iron-Man-style
/// holographic blue look.
class AppTheme {
  AppTheme._();

  static const Color backgroundColor = Color(0xFF02060C);
  static const Color panelColor = Color(0xFF071826);
  static const Color primaryBlue = Color(0xFF00E5FF);
  static const Color secondaryBlue = Color(0xFF0091EA);
  static const Color deepBlue = Color(0xFF002233);
  static const Color userBubbleColor = Color(0xFF0D3B54);
  static const Color aiBubbleColor = Color(0xFF07212F);
  static const Color textColor = Color(0xFFE0F7FF);
  static const Color mutedTextColor = Color(0xFF6FA8C2);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryBlue,
      fontFamily: 'monospace',
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: panelColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: primaryBlue,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
      ),
    );
  }
}
