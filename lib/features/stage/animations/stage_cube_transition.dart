import 'package:flutter/material.dart';

import 'stage_transition.dart';

/// Кубический переход: каждая страница вращается в 3D как грань куба
/// при свайпе пальцем.
class StageCubeTransition extends StageStepTransition {
  const StageCubeTransition();

  @override
  String get id => 'cube';

  @override
  String get label => 'Кубический';

  @override
  Widget build({
    required BuildContext context,
    required int pageCount,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required IndexedWidgetBuilder pageBuilder,
  }) {
    return _CubeView(
      pageCount: pageCount,
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      pageBuilder: pageBuilder,
    );
  }
}

class _CubeView extends StatefulWidget {
  const _CubeView({
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
  State<_CubeView> createState() => _CubeViewState();
}

class _CubeViewState extends State<_CubeView> {
  late final PageController _controller = PageController(
    initialPage: widget.currentIndex,
  );

  @override
  void didUpdateWidget(covariant _CubeView oldWidget) {
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
            final clamped = delta.clamp(-1.0, 1.0);
            // Перспектива куба: 90° поворот по Y между страницами
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(clamped * (3.14159 / 2));
            final alignment = clamped > 0
                ? Alignment.centerLeft
                : Alignment.centerRight;
            return Transform(
              alignment: alignment,
              transform: matrix,
              child: child,
            );
          },
          child: widget.pageBuilder(context, index),
        );
      },
    );
  }
}
