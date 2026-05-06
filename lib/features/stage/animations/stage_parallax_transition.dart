import 'package:flutter/material.dart';

import 'stage_transition.dart';

/// Карусель с параллаксом: соседняя страница немного уменьшена и
/// уезжает в фон, активная — крупнее и впереди.
class StageParallaxTransition extends StageStepTransition {
  const StageParallaxTransition();

  @override
  String get id => 'parallax';

  @override
  String get label => 'Параллакс';

  @override
  Widget build({
    required BuildContext context,
    required int pageCount,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required IndexedWidgetBuilder pageBuilder,
  }) {
    return _ParallaxView(
      pageCount: pageCount,
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      pageBuilder: pageBuilder,
    );
  }
}

class _ParallaxView extends StatefulWidget {
  const _ParallaxView({
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
  State<_ParallaxView> createState() => _ParallaxViewState();
}

class _ParallaxViewState extends State<_ParallaxView> {
  late final PageController _controller = PageController(
    initialPage: widget.currentIndex,
    viewportFraction: 0.92,
  );

  @override
  void didUpdateWidget(covariant _ParallaxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.currentIndex) {
      _controller.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 360),
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
            final scale = 1 - absDelta * 0.08;
            final opacity = 1 - absDelta * 0.35;
            return Center(
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
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
