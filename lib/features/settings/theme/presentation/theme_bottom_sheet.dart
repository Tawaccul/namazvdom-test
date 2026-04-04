import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_bottom_sheet.dart';
import '../../../../app/ui_kit/app_card.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../app/ui_kit/app_list_tile.dart';
import '../../../../app/ui_kit/app_top_bar.dart';

Future<ThemeMode?> showThemeBottomSheet(BuildContext context) {
  return showAppBottomSheet<ThemeMode?>(
    context: context,
    child: const _ThemeBottomSheet(),
  );
}

class _ThemeBottomSheet extends StatelessWidget {
  const _ThemeBottomSheet();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.themeControllerOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        children: [
          AppTopBar(
            title: context.t('theme.title'),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          SizedBox(height: 18.h),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final selectedMode = controller.mode;

              Widget tile({required ThemeMode mode, required String label}) {
                final selected = mode == selectedMode;
                return AppListTile(
                  title: label,
                  onTap: () {
                    controller.setMode(mode);
                    Navigator.of(context).pop<ThemeMode>(mode);
                  },
                  trailing: selected
                      ? Icon(
                          Icons.check,
                          size: 26.r,
                          color: context.colors.primary,
                        )
                      : SizedBox(width: 26.r, height: 26.r),
                );
              }

              return AppCard(
                radius: 32,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tile(
                      mode: ThemeMode.system,
                      label: context.t('theme.mode.system'),
                    ),
                    const AppDivider(insetLeft: 22, insetRight: 22),
                    tile(
                      mode: ThemeMode.light,
                      label: context.t('theme.mode.off'),
                    ),
                    const AppDivider(insetLeft: 22, insetRight: 22),
                    tile(
                      mode: ThemeMode.dark,
                      label: context.t('theme.mode.on'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
