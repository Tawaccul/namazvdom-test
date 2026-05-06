import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../onboarding/data/onboarding_repository_memory.dart';

class StageOnboardingState {
  StageOnboardingState({
    required void Function(VoidCallback) notify,
    required bool Function() isMounted,
    required GlobalKey? Function(String entryKey) getStepKey,
    required String Function() getOnboardingEntryKey,
    required Future<void> Function() animateToTop,
    required bool alwaysShow,
  })  : _notify = notify,
        _isMounted = isMounted,
        _getStepKey = getStepKey,
        _getOnboardingEntryKey = getOnboardingEntryKey,
        _animateToTop = animateToTop,
        _alwaysShow = alwaysShow;

  final void Function(VoidCallback) _notify;
  final bool Function() _isMounted;
  final GlobalKey? Function(String entryKey) _getStepKey;
  final String Function() _getOnboardingEntryKey;
  final Future<void> Function() _animateToTop;
  final bool _alwaysShow;

  bool showOnboarding = false;
  int stepIndex = 0;
  bool stepAdvancing = false;

  void initialize() {
    showOnboarding =
        _alwaysShow ||
        OnboardingRepositoryMemory.instance.consumeStageOnboarding();
    stepIndex = 0;
  }

  void onNext() {
    if (!showOnboarding || stepAdvancing) return;
    stepAdvancing = true;
    HapticFeedback.mediumImpact();
    if (stepIndex >= 2) {
      finish();
      stepAdvancing = false;
      return;
    }
    final next = stepIndex + 1;
    _notify(() => stepIndex = next);
    _handleStepChanged(next);
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!_isMounted()) return;
      stepAdvancing = false;
    });
  }

  void finish() {
    if (!showOnboarding) return;
    OnboardingRepositoryMemory.instance.completeStageOnboarding();
    _notify(() {
      showOnboarding = false;
      stepIndex = 0;
      stepAdvancing = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      _animateToTop();
    });
  }

  void _handleStepChanged(int step) {
    if (step != 2) return;
    _scrollStepIntoView();
  }

  void _scrollStepIntoView({int attempt = 0}) {
    final ctx = _getStepKey(_getOnboardingEntryKey())?.currentContext;
    if (ctx == null) {
      if (attempt >= 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isMounted() || !showOnboarding) return;
        _scrollStepIntoView(attempt: attempt + 1);
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted() || !showOnboarding) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      ).then((_) {
        if (!_isMounted() || !showOnboarding) return;
        _notify(() {});
      });
    });
  }
}
