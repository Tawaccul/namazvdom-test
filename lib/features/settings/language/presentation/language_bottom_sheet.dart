import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/pressable.dart';
import '../data/language_repository_memory.dart';
import '../domain/entities/app_language.dart';
import '../domain/usecases/get_available_languages.dart';
import '../domain/usecases/get_selected_language.dart';
import '../domain/usecases/set_selected_language.dart';
import 'language_controller.dart';

Future<AppLanguage?> showLanguageBottomSheet(BuildContext context) {
  return showModalBottomSheet<AppLanguage?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(70),
    builder: (context) {
      return DraggableScrollableSheet(
        minChildSize: 0.38,
        initialChildSize: 0.56,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.56, 0.92],
        builder: (context, scrollController) {
          final colors = context.colors;
          return SafeArea(
            top: false,
            bottom: false,
            child: Material(
              color: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _LanguageSheetHeaderDelegate(
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  _LanguageListSliver(),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _LanguageTile extends StatefulWidget {
  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hoverColor = Color.lerp(
      colors.soft,
      colors.backgroundLightBlue,
      Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.22,
    )!;
    final bg = _pressed ? hoverColor : colors.card;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: _pressed ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            widget.selected
                ? SvgPicture.asset(
                    'assets/icons/check.svg',
                    width: 15.r,
                    height: 11.r,
                    colorFilter: ColorFilter.mode(
                      colors.primary,
                      BlendMode.srcIn,
                    ),
                  )
                : SizedBox(width: 26.r, height: 26.r),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LanguageSheetHeaderDelegate({required this.onClose});

  final VoidCallback onClose;

  @override
  double get minExtent => 86.h;

  @override
  double get maxExtent => 86.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
      color: colors.card,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('language.chooseLanguage'),
                  style: TextStyle(
                    fontSize: 20.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Pressable(
                onTap: onClose,
                borderRadius: BorderRadius.circular(AppRadii.circle.r),
                child: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: colors.soft,
                    borderRadius: BorderRadius.circular(AppRadii.circle.r),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/close-icon.svg',
                    width: 24.r,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LanguageSheetHeaderDelegate oldDelegate) {
    return true;
  }
}

class _LanguageListSliver extends StatefulWidget {
  @override
  State<_LanguageListSliver> createState() => _LanguageListSliverState();
}

class _LanguageListSliverState extends State<_LanguageListSliver> {
  late final LanguageController _controller;

  @override
  void initState() {
    super.initState();
    final repository = LanguageRepositoryMemory.instance;
    _controller = LanguageController(
      getAvailableLanguages: GetAvailableLanguages(repository),
      getSelectedLanguage: GetSelectedLanguage(repository),
      setSelectedLanguage: SetSelectedLanguage(repository),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final itemCount = _controller.languages.length;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 0),
            child: Column(
              children: [
                for (var i = 0; i < itemCount; i++) ...[
                  _LanguageTile(
                    title: localizedLanguageLabel(
                      context,
                      _controller.languages[i].id,
                    ),
                    selected:
                        _controller.languages[i].id == _controller.selected.id,
                    onTap: () async {
                      final language = _controller.languages[i];
                      _controller.select(language);
                      await context.setLocale(Locale(language.id));
                      if (!context.mounted) return;
                      Navigator.of(context).pop<AppLanguage>(language);
                    },
                  ),
                  if (i != itemCount - 1)
                    const AppDivider(insetLeft: 8, insetRight: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
