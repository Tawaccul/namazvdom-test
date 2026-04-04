import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../app/app_scope.dart';
import 'dark_theme_screen.dart';
import 'text_size_screen.dart';
import 'theme_settings_style.dart';
import 'theme_text_size_store.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = AppScope.themeControllerOf(context).mode;
    final themeLabel = switch (themeMode) {
      ThemeMode.system => context.t('theme.mode.system'),
      ThemeMode.light => context.t('theme.mode.off'),
      ThemeMode.dark => context.t('theme.mode.on'),
    };

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
                      title: context.t('theme.darkTheme'),
                      trailing: themeLabel,
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
                      trailing: _textSizeLabel(context),
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

  String _textSizeLabel(BuildContext context) {
    return switch (ThemeTextSizeStore.indexFor(ThemeTextSizeStore.normalized)) {
      0 => context.t('theme.textSizeLabel.small'),
      1 => context.t('theme.textSizeLabel.standard'),
      _ => context.t('theme.textSizeLabel.large'),
    };
  }
}

class _ThemeMenuRow extends StatelessWidget {
  const _ThemeMenuRow({
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String trailing;
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
            SizedBox(width: 12.w),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                height: 1.36,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
