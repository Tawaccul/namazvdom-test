import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prayday/app/theme/app_radii.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../../app/ui_kit/app_card.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../app/ui_kit/app_list_tile.dart';
import '../../../../app/ui_kit/app_top_bar.dart';

class DarkThemeScreen extends StatefulWidget {
  const DarkThemeScreen({super.key});

  @override
  State<DarkThemeScreen> createState() => _DarkThemeScreenState();
}

class _DarkThemeScreenState extends State<DarkThemeScreen> {
  static const double _blurShowOffset = 100;
  final ScrollController _scrollController = ScrollController();
  bool _showTopBlur = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _blurShowOffset;
    if (shouldShow == _showTopBlur) return;
    setState(() => _showTopBlur = shouldShow);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = AppScope.themeControllerOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 28.h),
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 12.h,
                ),
                children: [
                  AppTopBar(
                    title: context.t('theme.theme'),
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(height: 24.h),
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
                              title: context.t('theme.mode.light'),
                              selected: controller.mode == ThemeMode.light,
                              onTap: () => controller.setMode(ThemeMode.light),
                            ),
                            const AppDivider(insetLeft: 22, insetRight: 22),
                            _ModeRow(
                              title: context.t('theme.mode.dark'),
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
          ],
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
