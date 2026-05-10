import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/pressable.dart';

class StageTopBar extends StatelessWidget {
  const StageTopBar({
    super.key,
    required this.onBack,
    required this.onStage,
    this.stageButtonKey,
  });

  final VoidCallback onBack;
  final VoidCallback onStage;
  final GlobalKey? stageButtonKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Pressable(
          onTap: onBack,
          triggerOnTapDown: true,
          child: Container(
            constraints: BoxConstraints(minWidth: 128.w),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 41.w,
                  height: 41.h,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppRadii.circle),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/back.svg',
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.none,
                    width: 7.w,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  context.t('common.back'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 2,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Pressable(
              onTap: onStage,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                key: stageButtonKey,
                padding: EdgeInsets.only(left: 14.w, top: 10.h, bottom: 10.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/slider-horizontal.svg',
                      colorFilter: ColorFilter.mode(
                        colors.textPrimary,
                        BlendMode.srcIn,
                      ),
                      width: 24.w,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        context.t('stage.selectStage'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
