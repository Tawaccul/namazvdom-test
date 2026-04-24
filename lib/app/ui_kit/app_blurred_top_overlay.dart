import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../theme/app_colors.dart';

class AppBlurredTopOverlay extends StatelessWidget {
  const AppBlurredTopOverlay({
    super.key,
    required this.child,
    this.visible = true,
    this.height = 150,
    this.maxBlurSigma = 60,
  });

  final Widget child;
  final bool visible;
  final double height;
  final double maxBlurSigma;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          ignoring: true,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: visible ? 1 : 0),
            builder: (context, opacity, _) {
              if (opacity <= 0.001) return const SizedBox.shrink();
              final sigma = maxBlurSigma * opacity;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: height.h,
                  width: double.infinity,
                  child: SoftEdgeBlur(
                    edges: [
                      EdgeBlur(
                        type: EdgeType.topEdge,
                        size: height.h,
                        tileMode: TileMode.mirror,
                        tintColor: colors.background.withValues(
                          alpha: 0.6 * opacity,
                        ),
                        sigma: sigma,
                        controlPoints: [
                          ControlPoint(
                            position: 0,
                            type: ControlPointType.visible,
                          ),
                          ControlPoint(
                            position: 1,
                            type: ControlPointType.transparent,
                          ),
                        ],
                      ),
                    ],
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: sigma,
                          sigmaY: sigma,
                        ),
                        child: ColoredBox(
                          color: colors.background.withValues(
                            alpha: 0.08 * opacity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
