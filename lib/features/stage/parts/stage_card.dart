import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';

class StageCard extends StatelessWidget {
  const StageCard({super.key, required this.child, this.withShadow = false});

  final Widget child;
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.only(right: 18.w, left: 18.w, top: 18.h, bottom: 18.h),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: withShadow
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class StageStepCard extends StatelessWidget {
  const StageStepCard({
    super.key,
    required this.imageWidget,
    required this.title,
    required this.description,
    required this.textSize,
  });

  final Widget imageWidget;
  final String title;
  final String description;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 244.h,
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(AppRadii.inner),
            ),
            child: Center(child: imageWidget),
          ),
          SizedBox(height: 19.h),
          Text(
            title,
            style: TextStyle(
              fontSize: textSize.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            description,
            style: TextStyle(
              fontSize: textSize.sp,
              height: 1.42,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
