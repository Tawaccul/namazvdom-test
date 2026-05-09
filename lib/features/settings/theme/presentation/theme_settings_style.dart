import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_top_bar.dart';

const kThemeSettingsScreenBg = Color(0xFFEFF1FB);
const kThemeSettingsTitleColor = Color(0xFF041E73);
const kThemeSettingsCardBg = Color(0xFFFBFBFD);
const kThemeSettingsBodyColor = Color(0xFF6272B1);
const kThemeSettingsMutedColor = Color(0xFF98A4C8);

class ThemeSettingsHeader extends StatelessWidget {
  const ThemeSettingsHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleBackButton(onTap: onBack),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
