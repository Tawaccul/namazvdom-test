import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/pressable.dart';

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
            child: _CircleBackButton(onTap: onBack),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = 22.r;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle),
        child: SvgPicture.asset(
          'assets/icons/back.svg',
          width: 7.r,
          height: 15.r,
          fit: BoxFit.none,
          colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
        ),
      ),
    );
  }
}
