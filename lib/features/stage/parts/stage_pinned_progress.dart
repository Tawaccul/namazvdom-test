import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import 'stage_progress_bar.dart';

class StagePinnedProgressCard extends StatelessWidget {
  const StagePinnedProgressCard({
    super.key,
    required this.rakaatIndex,
    required this.totalRakaats,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
    this.animateProgress = true,
  });

  final int rakaatIndex;
  final int totalRakaats;
  final int stepIndex;
  final int totalSteps;
  final double progress;
  final bool animateProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.secondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.t(
                    'stage.progress.steps',
                    namedArgs: {
                      'current': '$stepIndex',
                      'total': '$totalSteps',
                    },
                  ),
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
          SizedBox(height: 10.h),
          StageProgressBar(value: progress, animate: animateProgress),
        ],
      ),
    );
  }
}
