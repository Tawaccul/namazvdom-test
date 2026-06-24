import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class StageOverviewLayer<T> extends StatefulWidget {
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
    required this.canvasInset,
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
  final double canvasInset;
  final List<T> pages;
  final Size cardSize;
  final Offset Function(T page) pagePositionFor;
  final ValueChanged<T> onPageTap;
  final Widget Function(T page) pageBuilder;

  @override
  State<StageOverviewLayer<T>> createState() => _StageOverviewLayerState<T>();
}

class _StageOverviewLayerState<T> extends State<StageOverviewLayer<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollAnim;

  @override
  void initState() {
    super.initState();
    _scrollAnim = AnimationController.unbounded(vsync: this)
      ..addListener(_onScrollAnimTick);
    widget.transformationController.addListener(_onMatrixChanged);
  }

  @override
  void didUpdateWidget(StageOverviewLayer<T> old) {
    super.didUpdateWidget(old);
    if (old.transformationController != widget.transformationController) {
      old.transformationController.removeListener(_onMatrixChanged);
      widget.transformationController.addListener(_onMatrixChanged);
    }
    // Когда pan заблокирован снаружи (overview закрывается / лочится
    // жестами) — гасим ballistic-инерцию чтобы она не модифицировала
    // transform во время close-анимации.
    if (old.panEnabled && !widget.panEnabled && _scrollAnim.isAnimating) {
      _scrollAnim.stop();
    }
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onMatrixChanged);
    _scrollAnim.dispose();
    super.dispose();
  }

  // Sync scroll animation value → TransformationController X translation.
  void _onScrollAnimTick() {
    if (!mounted) return;
    final dx = _clamp(_scrollAnim.value);
    if ((dx - _scrollAnim.value).abs() > 0.5) {
      // Hit the wall — stop animation.
      _scrollAnim.stop();
      _writeX(dx);
      return;
    }
    _writeX(_scrollAnim.value);
  }

  // When the matrix changes from outside (pinch/open/close animations),
  // keep scroll anim in sync so the next drag starts from the right position.
  void _onMatrixChanged() {
    if (_scrollAnim.isAnimating) return;
    // Don't update — external writes are authoritative.
  }

  double get _currentX => widget.transformationController.value.storage[12];

  double _clamp(double dx) {
    final scale = widget.transformationController.value.storage[0]
        .clamp(widget.minScale, widget.maxScale)
        .toDouble();
    final canvasW = widget.canvasSize.width;
    final viewportW = context.size?.width ?? canvasW;
    final minX = viewportW - canvasW * scale;
    final maxX = 0.0;
    return dx.clamp(minX, maxX);
  }

  void _writeX(double dx) {
    final m = Matrix4.copy(widget.transformationController.value);
    m.storage[12] = dx;
    widget.transformationController.value = m;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _scrollAnim.stop();
    widget.onInteractionStart(details);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Forward to state helper for pinch-close detection.
    widget.onInteractionUpdate(details);

    // Single-finger pan: drive X directly with clamping.
    if (details.pointerCount == 1 && widget.panEnabled) {
      final next = _clamp(_currentX + details.focalPointDelta.dx);
      _writeX(next);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.onInteractionEnd(details);

    if (details.pointerCount > 0 || !widget.panEnabled) return;

    // Launch clamping ballistic scroll with iOS-like feel.
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() < 50) return;

    final dx = _currentX;
    _scrollAnim.animateWith(ClampingScrollSimulation(
      position: dx,
      velocity: velocity,
      friction: 0.015,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: context.colors.background,
      child: InteractiveViewer(
        transformationController: widget.transformationController,
        onInteractionStart: _handleScaleStart,
        onInteractionUpdate: _handleScaleUpdate,
        onInteractionEnd: _handleScaleEnd,
        boundaryMargin: EdgeInsets.zero,
        constrained: false,
        // Pan handled manually above; InteractiveViewer only does pinch-scale.
        panEnabled: false,
        scaleEnabled: widget.panEnabled,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: SizedBox(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final page in widget.pages)
                () {
                  final position = widget.pagePositionFor(page);
                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    width: widget.cardSize.width,
                    child: RepaintBoundary(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          // Перед переходом обязательно гасим
                          // ballistic-инерцию pan-а, иначе она продолжает
                          // двигать transformationController параллельно с
                          // анимацией закрытия overview и оставляет
                          // визуальные артефакты.
                          _scrollAnim.stop();
                          widget.onPageTap(page);
                        },
                        child: IgnorePointer(
                          ignoring: true,
                          child: widget.pageBuilder(page),
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
