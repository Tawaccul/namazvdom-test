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
    required this.stageButtonKey,
  });

  final VoidCallback onBack;
  final VoidCallback onStage;
  final GlobalKey stageButtonKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadowColor = Colors.black.withAlpha(13);
    return Row(
      children: [
        Pressable(
          onTap: onBack,
          borderRadius: BorderRadius.circular(AppRadii.circle),
          child: Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppRadii.circle),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
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
        ),
        SizedBox(width: 10.w),
        Text(
          context.t('common.back'),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
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
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
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
                          fontSize: 16.sp,
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
