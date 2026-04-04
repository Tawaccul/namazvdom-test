import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import 'stage_card.dart';

class StageProgressBlock extends StatelessWidget {
  const StageProgressBlock({
    super.key,
    required this.title,
    required this.rakaatIndex,
    required this.totalRakaats,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
    this.animateProgress = true,
  });

  final String title;
  final int rakaatIndex;
  final int totalRakaats;
  final int stepIndex;
  final int totalSteps;
  final double progress;
  final bool animateProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t(
                    'stage.progress.rakaats',
                    namedArgs: {
                      'current': '$rakaatIndex',
                      'total': '$totalRakaats',
                    },
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.secondary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  context.t(
                    'stage.progress.steps',
                    namedArgs: {
                      'current': '$stepIndex',
                      'total': '$totalSteps',
                    },
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          StageProgressBar(value: progress, animate: animateProgress),
        ],
      ),
    );
  }
}

class StageProgressBar extends StatelessWidget {
  const StageProgressBar({super.key, required this.value, this.animate = true});

  final double value;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12.h,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final filled = width * value.clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: colors.soft),
                  ),
                ),
                animate
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: filled,
                        height: 12.h,
                        decoration: BoxDecoration(color: colors.secondary),
                      )
                    : Container(
                        width: filled,
                        height: 12.h,
                        decoration: BoxDecoration(color: colors.secondary),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
