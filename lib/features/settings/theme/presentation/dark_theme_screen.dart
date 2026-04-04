import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:namazvdom/app/theme/app_radii.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_card.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../app/ui_kit/app_list_tile.dart';
import '../../../../app/ui_kit/app_top_bar.dart';

class DarkThemeScreen extends StatelessWidget {
  const DarkThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = AppScope.themeControllerOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              AppTopBar(
                title: context.t('theme.darkTheme'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(height: 22.h),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return AppCard(
                    radius: AppRadii.pill,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModeRow(
                          title: context.t('theme.mode.system'),
                          selected: controller.mode == ThemeMode.system,
                          onTap: () => controller.setMode(ThemeMode.system),
                        ),
                        const AppDivider(insetLeft: 22, insetRight: 22),
                        _ModeRow(
                          title: context.t('theme.mode.off'),
                          selected: controller.mode == ThemeMode.light,
                          onTap: () => controller.setMode(ThemeMode.light),
                        ),
                        const AppDivider(insetLeft: 22, insetRight: 22),
                        _ModeRow(
                          title: context.t('theme.mode.on'),
                          selected: controller.mode == ThemeMode.dark,
                          onTap: () => controller.setMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      onTap: onTap,
      trailing: selected
          ? SvgPicture.asset(
              'assets/icons/check.svg',
              width: 14,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
            )
          : SizedBox(width: 16.r, height: 16.r),
    );
  }
}
