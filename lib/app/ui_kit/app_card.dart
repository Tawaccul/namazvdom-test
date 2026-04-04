import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: BorderRadius.circular((radius ?? AppRadii.card).r),
      ),
      child: child,
    );
  }
}
