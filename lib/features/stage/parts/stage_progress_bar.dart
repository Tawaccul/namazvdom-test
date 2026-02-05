part of '../stage_step_screen.dart';

class _StageProgressBlock extends StatelessWidget {
  const _StageProgressBlock({
    required this.title,
    required this.rakaatIndex,
    required this.totalRakaats,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
  });

  final String title;
  final int rakaatIndex;
  final int totalRakaats;
  final int stepIndex;
  final int totalSteps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rakaatIndex of $totalRakaats rakats',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  '$stepIndex of $totalSteps steps',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          SizedBox(height: 12.h),
          _ProgressBar(value: progress),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
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
                    decoration: BoxDecoration(color: AppColors.soft),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: filled,
                  height: 12.h,
                  decoration: const BoxDecoration(color: AppColors.secondary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
