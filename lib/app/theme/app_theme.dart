import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.card,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: AppColors.dark, displayColor: AppColors.dark),
      iconTheme: const IconThemeData(color: AppColors.dark),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.divider,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.12),
      ),
    );
  }
}
