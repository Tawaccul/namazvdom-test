part of '../stage_step_screen.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onStage});

  final VoidCallback onBack;
  final VoidCallback onStage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: onBack,
          borderRadius: BorderRadius.circular(AppRadii.circle),
          child: Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.circle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/icons/back.svg',
              color: AppColors.dark,
              fit: BoxFit.none,
              width: 7.w,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          'Back',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.dark,
          ),
        ),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Pressable(
              onTap: onStage,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/slider-horizontal.svg',
                      color: AppColors.dark,
                      width: 24.w,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Select a stage',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark,
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
