import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.insetLeft, this.insetRight, this.color});

  final double? insetLeft;
  final double? insetRight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: (insetLeft ?? 0).w,
        right: (insetRight ?? 0).w,
      ),
      child: Container(height: 1, color: color ?? colors.divider),
    );
  }
}
