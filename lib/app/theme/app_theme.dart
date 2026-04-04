import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    return _build(palette: AppColors.light, brightness: Brightness.light);
  }

  static ThemeData dark() {
    return _build(palette: AppColors.dark, brightness: Brightness.dark);
  }

  static ThemeData _build({
    required AppColorPalette palette,
    required Brightness brightness,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        primary: palette.primary,
        surface: palette.card,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.divider,
        thumbColor: palette.primary,
        overlayColor: palette.primary.withAlpha(31),
      ),
    );
  }
}
