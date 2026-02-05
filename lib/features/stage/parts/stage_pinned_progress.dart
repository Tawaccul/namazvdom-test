part of '../stage_step_screen.dart';

class _PinnedProgressCard extends StatelessWidget {
  const _PinnedProgressCard({
    required this.rakaatIndex,
    required this.totalRakaats,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
  });

  final int rakaatIndex;
  final int totalRakaats;
  final int stepIndex;
  final int totalSteps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  '$rakaatIndex of $totalRakaats rakats',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '$stepIndex of $totalSteps steps',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _ProgressBar(value: progress),
        ],
      ),
    );
  }
}
