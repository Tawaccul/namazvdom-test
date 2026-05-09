import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class StageOverviewLayer<T> extends StatelessWidget {
  const StageOverviewLayer({
    super.key,
    required this.transformationController,
    required this.onInteractionStart,
    required this.onInteractionUpdate,
    required this.onInteractionEnd,
    required this.panEnabled,
    required this.interactionEndFrictionCoefficient,
    required this.minScale,
    required this.maxScale,
    required this.canvasSize,
    required this.pages,
    required this.cardSize,
    required this.pagePositionFor,
    required this.onPageTap,
    required this.pageBuilder,
  });

  final TransformationController transformationController;
  final GestureScaleStartCallback onInteractionStart;
  final GestureScaleUpdateCallback onInteractionUpdate;
  final GestureScaleEndCallback onInteractionEnd;
  final bool panEnabled;
  final double interactionEndFrictionCoefficient;
  final double minScale;
  final double maxScale;
  final Size canvasSize;
  final List<T> pages;
  final Size cardSize;
  final Offset Function(T page) pagePositionFor;
  final ValueChanged<T> onPageTap;
  final Widget Function(T page) pageBuilder;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: context.colors.background,
      child: InteractiveViewer(
        transformationController: transformationController,
        onInteractionStart: onInteractionStart,
        onInteractionUpdate: onInteractionUpdate,
        onInteractionEnd: onInteractionEnd,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        constrained: false,
        panEnabled: panEnabled,
        scaleEnabled: panEnabled,
        panAxis: PanAxis.horizontal,
        interactionEndFrictionCoefficient: interactionEndFrictionCoefficient,
        minScale: minScale,
        maxScale: maxScale,
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final page in pages)
                () {
                  final position = pagePositionFor(page);
                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    width: cardSize.width,
                    child: RepaintBoundary(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onPageTap(page),
                        child: IgnorePointer(
                          ignoring: true,
                          child: pageBuilder(page),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }
}
