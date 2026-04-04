import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/app_colors.dart';
import '../../core/widgets/pressable.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
    this.titleStyle,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleBackButton(onTap: onBack),
          ),
          Center(
            child: Text(
              title,
              style:
                  titleStyle ??
                  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1,
                  ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(child: trailing),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = 22.r;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle),
        child: SvgPicture.asset(
          'assets/icons/back.svg',
          width: 7.r,
          height: 15.r,
          fit: BoxFit.none,
          colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
        ),
      ),
    );
  }
}
