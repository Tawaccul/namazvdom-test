import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../stage/parts/stage_card.dart';
import '../../../stage/parts/stage_progress_bar.dart';

class AblutionProgressBlock extends StatelessWidget {
  const AblutionProgressBlock({
    super.key,
    required this.title,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
  });

  final String title;
  final int stepIndex;
  final int totalSteps;
  final double progress;

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
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            context.t(
              'ablution.progressSteps',
              namedArgs: {'current': '$stepIndex', 'total': '$totalSteps'},
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.secondary,
            ),
          ),
          SizedBox(height: 12),
          StageProgressBar(value: progress, animate: false),
        ],
      ),
    );
  }
}
