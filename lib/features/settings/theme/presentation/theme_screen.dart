import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/pressable.dart';
import 'dark_theme_screen.dart';
import 'text_size_screen.dart';
import 'theme_settings_style.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemeSettingsHeader(
                title: context.t('theme.title'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(height: 24.h),
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadii.pill.r),
                ),
                child: Column(
                  children: [
                    _ThemeMenuRow(
                      title: context.t('theme.theme'),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DarkThemeScreen(),
                          ),
                        );
                        if (!context.mounted) return;
                        setState(() {});
                      },
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      height: 1.h,
                      color: colors.divider,
                    ),
                    _ThemeMenuRow(
                      title: context.t('theme.textSize'),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TextSizeScreen(),
                          ),
                        );
                        if (!context.mounted) return;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeMenuRow extends StatelessWidget {
  const _ThemeMenuRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 22.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.36,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
