import 'package:flutter/material.dart';

import 'stage_transition.dart';

/// Карусель стеком: соседняя страница лежит позади и видна сверху,
/// активная — впереди и крупнее. Похоже на колоду карт.
class StageStackedTransition extends StageStepTransition {
  const StageStackedTransition();

  @override
  String get id => 'stacked';

  @override
  String get label => 'Стек карточек';

  @override
  Widget build({
    required BuildContext context,
    required int pageCount,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required IndexedWidgetBuilder pageBuilder,
  }) {
    return _StackedView(
      pageCount: pageCount,
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      pageBuilder: pageBuilder,
    );
  }
}

class _StackedView extends StatefulWidget {
  const _StackedView({
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
  State<_StackedView> createState() => _StackedViewState();
}

class _StackedViewState extends State<_StackedView> {
  late final PageController _controller = PageController(
    initialPage: widget.currentIndex,
    viewportFraction: 0.85,
  );

  @override
  void didUpdateWidget(covariant _StackedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.currentIndex) {
      _controller.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 380),
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
            final scale = 1 - absDelta * 0.18;
            final translateY = absDelta * -28;
            return Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: widget.pageBuilder(context, index),
        );
      },
    );
  }
}
