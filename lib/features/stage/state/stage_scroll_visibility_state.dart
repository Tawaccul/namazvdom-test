import 'package:flutter/material.dart';

class StageScrollVisibilityState {
  StageScrollVisibilityState({
    required void Function(VoidCallback) notify,
    required bool Function() isMounted,
    required BuildContext Function() getContext,
    required this.scrollController,
    required GlobalKey progressKey,
    required bool Function() isOverviewLayerShowing,
  })  : _notify = notify,
        _isMounted = isMounted,
        _getContext = getContext,
        _progressKey = progressKey,
        _isOverviewLayerShowing = isOverviewLayerShowing;

  final void Function(VoidCallback) _notify;
  final bool Function() _isMounted;
  final BuildContext Function() _getContext;
  final GlobalKey _progressKey;
  final bool Function() _isOverviewLayerShowing;

  final ScrollController scrollController;

  static const double _topBlurShowOffset = 10;

  bool showPinned = false;
  bool showTopBlur = false;
  bool showTopControls = true;
  int topControlsRevealToken = 0;
  bool contentAppeared = false;

  void onScroll() {
    if (_isOverviewLayerShowing()) {
      if (showPinned) _notify(() => showPinned = false);
      if (showTopBlur) _notify(() => showTopBlur = false);
      return;
    }
    updatePinned();
    updateTopBlur();
  }

  void updateTopBlur() {
    final shouldShow =
        scrollController.hasClients &&
        scrollController.offset > _topBlurShowOffset;
    if (shouldShow == showTopBlur) return;
    _notify(() => showTopBlur = shouldShow);
  }

  void updatePinned() {
    final context = _getContext();
    final progressCtx = _progressKey.currentContext;
    final stackBox = context.findRenderObject() as RenderBox?;
    if (progressCtx == null || stackBox == null) return;
    final progressBox = progressCtx.findRenderObject() as RenderBox?;
    if (progressBox == null || !progressBox.hasSize) return;
    final stackTop = stackBox.localToGlobal(Offset.zero).dy;
    final progressTop = progressBox.localToGlobal(Offset.zero).dy - stackTop;
    final progressBottom = progressTop + progressBox.size.height;
    const pinnedTop = 64;
    final shouldShow = progressBottom <= pinnedTop + 4;
    if (shouldShow != showPinned) {
      _notify(() => showPinned = shouldShow);
    }
  }

  void jumpToTop() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
  }

  void jumpScrollToTop() {
    if (!scrollController.hasClients) return;
    if (scrollController.offset == 0) return;
    scrollController.jumpTo(0);
  }

  Future<void> animateToTop() async {
    if (!scrollController.hasClients) return;
    await scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void markContentAppeared() {
    _notify(() => contentAppeared = true);
  }

  void scheduleTopControlsReveal() {
    final nextToken = topControlsRevealToken + 1;
    topControlsRevealToken = nextToken;
    Future<void>.delayed(Duration.zero, () {
      if (!_isMounted()) return;
      if (topControlsRevealToken != nextToken) return;
      if (_isOverviewLayerShowing()) return;
      if (showTopControls) return;
      _notify(() => showTopControls = true);
    });
  }
}
