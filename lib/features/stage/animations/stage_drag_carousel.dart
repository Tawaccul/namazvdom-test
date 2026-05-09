import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StageDragCarouselController {
  Future<void> Function()? _animateNext;
  Future<void> Function()? _animatePrev;

  Future<void> animateNext() async {
    final callback = _animateNext;
    if (callback == null) return;
    await callback();
  }

  Future<void> animatePrev() async {
    final callback = _animatePrev;
    if (callback == null) return;
    await callback();
  }
}

/// Карусель шагов: контент следует за пальцем, рядом сразу
/// показывается копия — даёт ощущение листающихся страниц.
/// Когда жест переключает шаг — родитель перерисовывает child
/// с новым содержимым, и сдвиг сбрасывается в 0.
class StageDragCarousel extends StatefulWidget {
  const StageDragCarousel({
    super.key,
    required this.childBuilder,
    required this.prevGhost,
    required this.nextGhost,
    required this.onNext,
    required this.onPrev,
    required this.canGoNext,
    required this.canGoPrev,
    this.onDragStarted,
    this.thresholdFraction = 0.28,
    this.controller,
    this.onProgrammaticNext,
    this.onProgrammaticPrev,
  });

  /// Вызывается, когда пользователь начал горизонтальный свайп
  /// между шагами. Можно использовать, чтобы, например, поднять
  /// внешний скролл к верху, чтобы новая страница появилась с начала.
  final VoidCallback? onDragStarted;

  /// Билдер активного контента (получает [dragProgress] 0..1).
  final Widget Function(BuildContext context, double dragProgress) childBuilder;

  /// Виджет-ghost для предыдущей страницы (или null, если её нет).
  /// Должен быть без GlobalKey'ев и без интерактива.
  final Widget? prevGhost;

  /// Виджет-ghost для следующей страницы.
  final Widget? nextGhost;
  final Future<void> Function() onNext;
  final Future<void> Function() onPrev;
  final Future<void> Function()? onProgrammaticNext;
  final Future<void> Function()? onProgrammaticPrev;
  final bool canGoNext;
  final bool canGoPrev;
  final double thresholdFraction;
  final StageDragCarouselController? controller;

  @override
  State<StageDragCarousel> createState() => _StageDragCarouselState();
}

class _StageDragCarouselState extends State<StageDragCarousel>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;
  bool _committing = false;
  late final AnimationController _settleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<double>? _settleAnimation;

  @override
  void initState() {
    super.initState();
    _bindController();
    _settleController.addListener(() {
      if (_settleAnimation == null) return;
      setState(() => _dragOffset = _settleAnimation!.value);
    });
  }

  @override
  void didUpdateWidget(covariant StageDragCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unbindController(oldWidget.controller);
      _bindController();
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    _settleController.dispose();
    super.dispose();
  }

  void _bindController() {
    final controller = widget.controller;
    if (controller == null) return;
    controller._animateNext = () => _animateProgrammaticCommit(next: true);
    controller._animatePrev = () => _animateProgrammaticCommit(next: false);
  }

  void _unbindController(StageDragCarouselController? controller) {
    if (controller == null) return;
    controller._animateNext = null;
    controller._animatePrev = null;
  }

  bool _isAllowedDirection(double delta) {
    if (delta < 0 && !widget.canGoNext) return false;
    if (delta > 0 && !widget.canGoPrev) return false;
    return true;
  }

  void _handleDragStart(DragStartDetails _) {
    _settleController.stop();
    _isDragging = true;
    _committing = false;
    widget.onDragStarted?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (!_isDragging) return;
    var next = _dragOffset + details.delta.dx;
    if (next < 0 && !widget.canGoNext) next = next * 0.25;
    if (next > 0 && !widget.canGoPrev) next = next * 0.25;
    next = next.clamp(-width, width);
    setState(() => _dragOffset = next);
  }

  Future<void> _handleDragEnd(DragEndDetails details, double width) async {
    if (!_isDragging) return;
    _isDragging = false;
    final threshold = width * widget.thresholdFraction;
    final velocity = details.primaryVelocity ?? 0;
    final shouldGoNext =
        widget.canGoNext && (_dragOffset <= -threshold || velocity <= -600);
    final shouldGoPrev =
        widget.canGoPrev && (_dragOffset >= threshold || velocity >= 600);

    if (shouldGoNext || shouldGoPrev) {
      _committing = true;
      // Никакой плавной доводки — мгновенно сбрасываем сдвиг и
      // переключаем шаг. Новый контент сразу окажется на месте.
      if (shouldGoNext) {
        unawaited(widget.onNext());
      } else {
        unawaited(widget.onPrev());
      }
      setState(() => _dragOffset = 0);
      _committing = false;
      return;
    }
    await _animateOffsetTo(0);
  }

  Future<void> _animateOffsetTo(double target) async {
    _settleAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutCubic),
    );
    _settleController
      ..stop()
      ..value = 0;
    await _settleController.forward(from: 0);
  }

  Future<void> _animateProgrammaticCommit({required bool next}) async {
    if (_isDragging || _committing) return;
    if (next && !widget.canGoNext) return;
    if (!next && !widget.canGoPrev) return;
    final width = _currentCarouselWidth();
    final travelDistance = width + 14.w;
    final callback = next
        ? (widget.onProgrammaticNext ?? widget.onNext)
        : (widget.onProgrammaticPrev ?? widget.onPrev);
    if (width <= 0) {
      await callback();
      return;
    }
    widget.onDragStarted?.call();
    _committing = true;
    try {
      _settleController.stop();
      await _animateOffsetTo(next ? -travelDistance : travelDistance);
      if (!mounted) return;
      await callback();
    } finally {
      if (mounted) {
        setState(() => _dragOffset = 0);
      } else {
        _dragOffset = 0;
      }
      _committing = false;
    }
  }

  double _currentCarouselWidth() {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox &&
        renderObject.hasSize &&
        renderObject.size.width > 0) {
      return renderObject.size.width;
    }
    return MediaQuery.sizeOf(context).width;
  }

  void _handleDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    if (_committing) return;
    _animateOffsetTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final gap = 14.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final constrainedWidth = constraints.maxWidth;
        final width = constrainedWidth.isFinite && constrainedWidth > 0
            ? constrainedWidth
            : MediaQuery.sizeOf(context).width;
        final dragProgress = width <= 0
            ? 0.0
            : (_dragOffset.abs() / width).clamp(0.0, 1.0);
        final mainContent = widget.childBuilder(context, dragProgress);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (details) {
            if (!_isAllowedDirection(details.delta.dx) && _dragOffset == 0) {
              return;
            }
            _handleDragUpdate(details, width);
          },
          onHorizontalDragEnd: (details) =>
              unawaited(_handleDragEnd(details, width)),
          onHorizontalDragCancel: _handleDragCancel,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: mainContent,
              ),
              if (widget.canGoPrev && widget.prevGhost != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Transform.translate(
                      offset: Offset(_dragOffset - width - gap, 0),
                      child: widget.prevGhost!,
                    ),
                  ),
                ),
              if (widget.canGoNext && widget.nextGhost != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Transform.translate(
                      offset: Offset(_dragOffset + width + gap, 0),
                      child: widget.nextGhost!,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
