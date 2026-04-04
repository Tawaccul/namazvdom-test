import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../core/widgets/pressable.dart';

Future<void> showMadhhabInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return const _MadhhabInfoSheet();
    },
  );
}

class _MadhhabInfoSheet extends StatelessWidget {
  const _MadhhabInfoSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      bottom: false,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.card.r),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: const _MadhhabInfoBody(),
      ),
    );
  }
}

class _MadhhabInfoBody extends StatefulWidget {
  const _MadhhabInfoBody();

  @override
  State<_MadhhabInfoBody> createState() => _MadhhabInfoBodyState();
}

class _MadhhabInfoBodyState extends State<_MadhhabInfoBody> {
  String? _expandedId;

  void _toggle(String id) {
    setState(() => _expandedId = (_expandedId == id) ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 48.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('madhhab.info.title'),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              Pressable(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(AppRadii.circle.r),
                child: SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: SvgPicture.asset(
                    'assets/icons/close-icon.svg',
                    width: 24.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            context.t('madhhab.info.paragraph1'),
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.48,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            context.t('madhhab.info.paragraph2'),
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.48,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          _Section(
            title: context.t('madhhab.info.sections.hanafi.title'),
            expanded: _expandedId == 'hanafi',
            onTap: () => _toggle('hanafi'),
            body: context.t('madhhab.info.sections.hanafi.body'),
          ),
          const AppDivider(insetLeft: 0, insetRight: 0),
          _Section(
            title: context.t('madhhab.info.sections.maliki.title'),
            expanded: _expandedId == 'maliki',
            onTap: () => _toggle('maliki'),
            body: context.t('madhhab.info.sections.maliki.body'),
          ),
          const AppDivider(insetLeft: 0, insetRight: 0),
          _Section(
            title: context.t('madhhab.info.sections.shafii.title'),
            expanded: _expandedId == 'shafii',
            onTap: () => _toggle('shafii'),
            body: context.t('madhhab.info.sections.shafii.body'),
          ),
          const AppDivider(insetLeft: 0, insetRight: 0),
          _Section(
            title: context.t('madhhab.info.sections.hanbali.title'),
            expanded: _expandedId == 'hanbali',
            onTap: () => _toggle('hanbali'),
            body: context.t('madhhab.info.sections.hanbali.body'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.body,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: SvgPicture.asset(
                    'assets/icons/arrow-bottom.svg',
                    width: 15.r,
                    height: 7.r,
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Text(
              body,
              style: TextStyle(
                fontSize: 16.sp,
                height: 1.48,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
