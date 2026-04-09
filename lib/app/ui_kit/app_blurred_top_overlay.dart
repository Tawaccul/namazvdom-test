import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

class AppBlurredTopOverlay extends StatelessWidget {
  const AppBlurredTopOverlay({
    super.key,
    this.child,
    this.visible = true,
    this.horizontalPadding = 16,
    this.topSpacing = 12,
    this.height = 20,
  });

  final Widget? child;
  final bool visible;
  final double horizontalPadding;
  final double topSpacing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final safeTop = MediaQuery.paddingOf(context).top;
    final background = colors.background;

    return SizedBox(
      height: safeTop + height.h,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          background.withValues(alpha: 0.62),
                          background.withValues(alpha: 0.34),
                          background.withValues(alpha: 0.10),
                          background.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.22, 0.58, 1],
                      ),
                    ),
                  ),
                ),
              ),
              if (child != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding.w,
                    safeTop + topSpacing.h,
                    horizontalPadding.w,
                    0,
                  ),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
