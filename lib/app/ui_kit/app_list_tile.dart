import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prayday/app/theme/app_radii.dart';

import '../theme/app_colors.dart';
import '../../core/widgets/pressable.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
    this.padding,
    this.titleStyle,
  });

  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: Padding(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style:
                    titleStyle ??
                    TextStyle(
                      fontSize: 16.sp,
                      height: 1.36,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
