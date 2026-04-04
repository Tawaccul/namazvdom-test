import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/ui_kit/app_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../settings/madhhab/data/madhhab_repository_memory.dart';
import '../../settings/madhhab/domain/entities/app_madhhab.dart';
import '../../settings/madhhab/domain/usecases/get_available_madhhabs.dart';
import '../../settings/madhhab/domain/usecases/get_selected_madhhab.dart';
import '../../settings/madhhab/domain/usecases/set_selected_madhhab.dart';
import '../../settings/madhhab/presentation/madhhab_controller.dart';
import '../../settings/madhhab/presentation/madhhab_info_sheet.dart';

class OnboardingMadhhabScreen extends StatefulWidget {
  const OnboardingMadhhabScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingMadhhabScreen> createState() =>
      _OnboardingMadhhabScreenState();
}

class _OnboardingMadhhabScreenState extends State<OnboardingMadhhabScreen> {
  late final MadhhabController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final repo = MadhhabRepositoryMemory.instance;
    _controller = MadhhabController(
      getAvailableMadhhabs: GetAvailableMadhhabs(repo),
      getSelectedMadhhab: GetSelectedMadhhab(repo),
      setSelectedMadhhab: SetSelectedMadhhab(repo),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 7),
                  Text(
                    context.t('onboarding.madhhab.title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.48,
                        fontWeight: FontWeight.w400,
                        color: colors.textMuted,
                      ),
                      children: [
                        TextSpan(
                          text: context.t(
                            'onboarding.madhhab.recommendationStart',
                          ),
                        ),
                        TextSpan(
                          text: context.t(
                            'onboarding.madhhab.recommendationMid',
                          ),
                          style: TextStyle(color: colors.primary),
                        ),
                        TextSpan(
                          text: context.t(
                            'onboarding.madhhab.recommendationEnd',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                  _MadhhabDropdown(
                    expanded: _expanded,
                    selected: _controller.selected,
                    items: _controller.madhhabs,
                    onToggle: () => setState(() => _expanded = !_expanded),
                    onSelect: (m) {
                      if (m.id != _controller.selected.id) {
                        _controller.select(m);
                      }
                      setState(() => _expanded = false);
                    },
                  ),
                  const Spacer(flex: 10),
                  AppButton(
                    label: context.t('common.next'),
                    onPressed: widget.onNext,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                  ),
                  SizedBox(height: 24.h),
                  Pressable(
                    onTap: () => showMadhhabInfoSheet(context),
                    borderRadius: BorderRadius.circular(AppRadii.pill.r),
                    child: Text(
                      context.t('onboarding.madhhab.learnMore'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MadhhabDropdown extends StatelessWidget {
  const _MadhhabDropdown({
    required this.expanded,
    required this.selected,
    required this.items,
    required this.onToggle,
    required this.onSelect,
  });

  final bool expanded;
  final AppMadhhab selected;
  final List<AppMadhhab> items;
  final VoidCallback onToggle;
  final ValueChanged<AppMadhhab> onSelect;

  @override
  Widget build(BuildContext context) {
    final tiles = expanded
        ? items
              .map(
                (m) => _MadhhabTile(
                  madhhab: m,
                  selected: m.id == selected.id,
                  mode: _MadhhabTileMode.select,
                  onTap: () => onSelect(m),
                ),
              )
              .toList()
        : [
            _MadhhabTile(
              madhhab: selected,
              selected: true,
              mode: _MadhhabTileMode.dropdown,
              onTap: onToggle,
            ),
          ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i != 0) SizedBox(height: 16.h),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

enum _MadhhabTileMode { dropdown, select }

class _MadhhabTile extends StatefulWidget {
  const _MadhhabTile({
    required this.madhhab,
    required this.selected,
    required this.mode,
    required this.onTap,
  });

  final AppMadhhab madhhab;
  final bool selected;
  final _MadhhabTileMode mode;
  final VoidCallback onTap;

  @override
  State<_MadhhabTile> createState() => _MadhhabTileState();
}

class _MadhhabTileState extends State<_MadhhabTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = colors.card.withAlpha(155);
    final baseColor = isDark ? colors.soft : colors.card;
    final bg = _pressed ? hoverColor : baseColor;

    final trailing = switch (widget.mode) {
      _MadhhabTileMode.dropdown => SvgPicture.asset(
        'assets/icons/arrow-bottom.svg',
        width: 15.r,
        height: 7.r,
        colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
      ),
      _MadhhabTileMode.select => _MadhhabCheck(selected: widget.selected),
    };

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: _pressed ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      localizedMadhhabLabel(context, widget.madhhab.id),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  if (widget.madhhab.recommended)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.backgroundLightBlue,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        context.t('onboarding.madhhab.recommendedBadge'),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _MadhhabCheck extends StatelessWidget {
  const _MadhhabCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        color: selected ? colors.card : colors.soft,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: selected ? colors.secondary : colors.divider,
          width: selected ? 4.w : 0,
        ),
      ),
    );
  }
}
