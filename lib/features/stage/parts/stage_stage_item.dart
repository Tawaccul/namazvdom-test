part of '../stage_step_screen.dart';

class _StageItem extends StatelessWidget {
  const _StageItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.nightlight_round,
                color: AppColors.primary,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22.r),
          ],
        ),
      ),
    );
  }
}
