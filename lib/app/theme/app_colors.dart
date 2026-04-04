import 'package:flutter/material.dart';

@immutable
class AppColorPalette {
  const AppColorPalette({
    required this.background,
    required this.backgroundLightBlue,
    required this.card,
    required this.soft,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.darkButton,
    required this.darkButtonPressed,
    required this.darkButtonMuted,
  });

  final Color background;
  final Color card;
  final Color soft;
  final Color backgroundLightBlue;
  final Color primary;
  final Color secondary;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color divider;

  final Color darkButton;
  final Color darkButtonPressed;
  final Color darkButtonMuted;
}

class AppColors {
  static const light = AppColorPalette(
    background: Color(0xFFF0F4FF),
    backgroundLightBlue: (Color(0xFFD7E7FF)),
    card: Color(0xFFFFFFFF),
    soft: Color(0xFFF7F9FF),
    primary: Color(0xFF497FFF),
    secondary: Color(0xFF1054FF),
    textPrimary: Color(0xFF02186C),
    textSecondary: Color(0xFF6572A4),
    textMuted: Color(0xFFA7AFCF),
    divider: Color(0xFFF0F4FF),
    darkButton: Color(0xFF2B2C33),
    darkButtonPressed: Color(0xFF23242A),
    darkButtonMuted: Color(0xFF7D8090),
  );

  static const dark = AppColorPalette(
    background: Color(0xFF1E1F27),
    backgroundLightBlue: (Color(0xFF2D3350)),
    card: Color(0xFF2A2B35),
    soft: Color(0xFF323444),
    primary: Color(0xFF497FFF),
    secondary: Color(0xFF2B4CFF),
    textPrimary: Color(0xFFF4F6FF),
    textSecondary: Color(0xFFB9BCD0),
    textMuted: Color(0xFF8A8D9F),
    divider: Color(0xFF3A3C48),
    darkButton: Color(0xFF2B2C33),
    darkButtonPressed: Color(0xFF23242A),
    darkButtonMuted: Color(0xFF7D8090),
  );

  static AppColorPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

extension AppColorsX on BuildContext {
  AppColorPalette get colors => AppColors.of(this);
}
