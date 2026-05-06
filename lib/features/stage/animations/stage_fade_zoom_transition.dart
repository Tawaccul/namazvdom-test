import 'package:flutter/material.dart';

import 'stage_transition.dart';

/// Мягкая анимация: соседняя страница появляется через прозрачность
/// и небольшое приближение по zoom — почти без горизонтального сдвига.
class StageFadeZoomTransition extends StageStepTransition {
  const StageFadeZoomTransition();

  @override
  String get id => 'fade_zoom';

  @override
  String get label => 'Появление';

  @override
  Widget build({
    required BuildContext context,
    required int pageCount,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required IndexedWidgetBuilder pageBuilder,
  }) {
    return _FadeZoomView(
      pageCount: pageCount,
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      pageBuilder: pageBuilder,
    );
  }
}

class _FadeZoomView extends StatefulWidget {
  const _FadeZoomView({
    required this.pageCount,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.pageBuilder,
  });

  final int pageCount;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final IndexedWidgetBuilder pageBuilder;

  @override
  State<_FadeZoomView> createState() => _FadeZoomViewState();
}

class _FadeZoomViewState extends State<_FadeZoomView> {
  late final PageController _controller = PageController(
    initialPage: widget.currentIndex,
  );

  @override
  void didUpdateWidget(covariant _FadeZoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.currentIndex) {
      _controller.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.pageCount,
      onPageChanged: widget.onIndexChanged,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double delta = 0;
            if (_controller.position.haveDimensions) {
              delta = (_controller.page ?? widget.currentIndex.toDouble()) -
                  index;
            } else {
              delta = (widget.currentIndex - index).toDouble();
            }
            final absDelta = delta.abs().clamp(0.0, 1.0);
            // Лёгкий zoom + затухание + малый горизонтальный сдвиг
            final scale = 0.92 + (1 - absDelta) * 0.08;
            final opacity = (1 - absDelta * 1.4).clamp(0.0, 1.0);
            return Transform.translate(
              // Гасим стандартный сдвиг PageView, оставляя только 30%
              offset: Offset(-delta * MediaQuery.sizeOf(context).width * 0.7, 0),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
          child: widget.pageBuilder(context, index),
        );
      },
    );
  }
}
