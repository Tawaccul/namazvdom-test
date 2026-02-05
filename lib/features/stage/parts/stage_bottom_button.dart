part of '../stage_step_screen.dart';

enum _BottomButtonVariant { primary, secondary }

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.variant,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final _BottomButtonVariant variant;
  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == _BottomButtonVariant.primary;
    final bg = isPrimary ? AppColors.primary : AppColors.card;
    final fg = isPrimary ? AppColors.card : AppColors.dark;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: Container(
        height: 58.h,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isPrimary
                ? [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SvgPicture.asset(icon, width: 22.w, color: fg),
                  ]
                : [
                    SvgPicture.asset(icon, width: 22.w, color: fg),
                    SizedBox(width: 12.w),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
