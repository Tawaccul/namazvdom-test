import 'package:flutter/material.dart';

import 'stage_transition.dart';

/// Классическая карусель: контент следует за пальцем, соседняя
/// страница плавно появляется. Базовый PageView со снаппингом.
class StageCarouselTransition extends StageStepTransition {
  const StageCarouselTransition();

  @override
  String get id => 'carousel';

  @override
  String get label => 'Карусель';

  @override
  Widget build({
    required BuildContext context,
    required int pageCount,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required IndexedWidgetBuilder pageBuilder,
  }) {
    return _CarouselView(
      pageCount: pageCount,
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      pageBuilder: pageBuilder,
    );
  }
}

class _CarouselView extends StatefulWidget {
  const _CarouselView({
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
  State<_CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<_CarouselView> {
  late final PageController _controller = PageController(
    initialPage: widget.currentIndex,
  );

  @override
  void didUpdateWidget(covariant _CarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.currentIndex) {
      _controller.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 320),
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
      itemBuilder: widget.pageBuilder,
    );
  }
}
