import 'dart:async';

import 'package:flutter/material.dart';

import '../models/stage_step_screen_models.dart';

class StageOverviewStateHelper {
  static void handleOverviewTransformChanged({
    required bool showOverviewLayer,
    required bool isAnimatingOverviewMatrix,
    required bool isClampingOverviewTransform,
    required Matrix4 Function(Matrix4 matrix) clampOverviewTransformYOnly,
    required TransformationController transformationController,
    required bool Function(Matrix4 a, Matrix4 b) matricesAreEqual,
    required void Function(bool value) setIsClampingOverviewTransform,
  }) {
    if (!showOverviewLayer ||
        isAnimatingOverviewMatrix ||
        isClampingOverviewTransform) {
      return;
    }
    final clamped = clampOverviewTransformYOnly(transformationController.value);
    final current = transformationController.value;
    if (matricesAreEqual(current, clamped)) {
      return;
    }
    setIsClampingOverviewTransform(true);
    transformationController.value = clamped;
    setIsClampingOverviewTransform(false);
  }

  static void handleOverviewPanUpdate({
    required ScaleUpdateDetails details,
    required bool isAnimatingOverviewMatrix,
    required bool isClampingOverviewTransform,
    required bool overviewGestureLock,
    required bool overviewPinchCloseTriggered,
    required int overviewSelectedFlatIndex,
    required int? overviewPendingCloseFlatIndex,
    required double overviewPreviewScale,
    required double overviewCloseScaleThreshold,
    required double overviewPanSpeedMultiplier,
    required bool mounted,
    required TransformationController transformationController,
    required int Function(Offset viewportPoint) flatIndexForViewportPoint,
    required int Function() nearestFlatIndexFromCurrentTransform,
    required StagePageReference? Function(int flatIndex) pageForFlatIndex,
    required Matrix4 Function(StagePageReference page, {double scale})
    overviewMatrixForPage,
    required Matrix4 Function(Matrix4 matrix) clampOverviewTransform,
    required Future<void> Function() closeOverviewFromPinch,
    required void Function(int value) setOverviewSelectedFlatIndex,
    required void Function(int? value) setOverviewPendingCloseFlatIndex,
    required void Function(bool value) setOverviewPinchCloseTriggered,
    required void Function(bool value) setOverviewGestureLock,
    required void Function(bool value) setIsClampingOverviewTransform,
    required void Function(VoidCallback fn) setStateSafe,
  }) {
    if (isAnimatingOverviewMatrix || isClampingOverviewTransform) return;
    if (overviewGestureLock || overviewPinchCloseTriggered) return;

    if (details.pointerCount >= 2) {
      final targetFlatIndex = flatIndexForViewportPoint(
        details.localFocalPoint,
      );
      setOverviewPendingCloseFlatIndex(targetFlatIndex);
      if (overviewSelectedFlatIndex != targetFlatIndex && mounted) {
        setStateSafe(() => setOverviewSelectedFlatIndex(targetFlatIndex));
      }
      final currentScale = transformationController.value.storage[0]
          .clamp(overviewPreviewScale, 1.0)
          .toDouble();
      if (details.scale >= overviewCloseScaleThreshold ||
          currentScale >= overviewCloseScaleThreshold) {
        setOverviewPinchCloseTriggered(true);
        final closestFlatIndex =
            overviewPendingCloseFlatIndex ??
            nearestFlatIndexFromCurrentTransform();
        final page = pageForFlatIndex(closestFlatIndex);
        if (page == null) return;
        transformationController.value = overviewMatrixForPage(
          page,
          scale: overviewPreviewScale,
        );
        if (mounted) {
          setStateSafe(() {
            setOverviewSelectedFlatIndex(closestFlatIndex);
            setOverviewGestureLock(true);
          });
        }
        unawaited(closeOverviewFromPinch());
      }
      return;
    }

    final extraDx =
        details.focalPointDelta.dx * (overviewPanSpeedMultiplier - 1);
    if (extraDx.abs() < 0.01) return;
    final boosted = Matrix4.copy(transformationController.value)
      ..translateByDouble(extraDx, 0, 0, 1);
    setIsClampingOverviewTransform(true);
    transformationController.value = clampOverviewTransform(boosted);
    setIsClampingOverviewTransform(false);
  }

  static Future<void> animateOverviewMatrix({
    required bool mounted,
    required AnimationController overviewAnimationController,
    required TransformationController transformationController,
    required Matrix4 target,
    required void Function(bool value) setIsAnimatingOverviewMatrix,
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!mounted) return;
    overviewAnimationController
      ..stop()
      ..duration = duration
      ..reset();
    final animation =
        Matrix4Tween(
          begin: Matrix4.copy(transformationController.value),
          end: target,
        ).animate(
          CurvedAnimation(parent: overviewAnimationController, curve: curve),
        );

    void listener() {
      transformationController.value = animation.value;
    }

    setIsAnimatingOverviewMatrix(true);
    animation.addListener(listener);
    try {
      await overviewAnimationController.forward();
    } finally {
      animation.removeListener(listener);
      transformationController.value = target;
      setIsAnimatingOverviewMatrix(false);
    }
  }

  static Future<void> openOverviewMode({
    required bool isOverviewMode,
    required bool showOverviewLayer,
    required bool isAnimatingOverviewMatrix,
    required bool isStageTransitioning,
    required int currentFlatPageIndex,
    required StagePageReference? Function(int flatIndex) pageForFlatIndex,
    required void Function({bool disableAutoplay}) cancelAutoplaySequence,
    required Future<void> Function() pauseAudio,
    required bool mounted,
    required TransformationController transformationController,
    required Matrix4 Function(StagePageReference page, {double scale})
    overviewMatrixForPage,
    required double overviewPreviewScale,
    required Future<void> Function(
      Matrix4 target, {
      Duration duration,
      Curve curve,
    })
    animateOverviewMatrix,
    required void Function(int value) setTopControlsRevealToken,
    required int topControlsRevealToken,
    required void Function(VoidCallback fn) setStateSafe,
    required void Function(int value) setOverviewOriginFlatIndex,
    required void Function(int value) setOverviewSelectedFlatIndex,
    required void Function(bool value) setOverviewPinchCloseTriggered,
    required void Function(bool value) setOverviewGestureLock,
    required void Function(int? value) setOverviewPendingCloseFlatIndex,
    required void Function(bool value) setShowTopControls,
    required void Function(bool value) setShowOverviewLayer,
    required void Function(bool value) setIsOverviewMode,
    required void Function(bool value) setIsOverviewClosing,
    required void Function(bool value) setShowOverviewExitButton,
    required void Function(bool value) setShowPinned,
    required VoidCallback clearAudioPlaybackKeys,
    required bool Function() isOverviewLayerShown,
  }) async {
    if (isOverviewMode ||
        showOverviewLayer ||
        isAnimatingOverviewMatrix ||
        isStageTransitioning) {
      return;
    }
    final currentPage = pageForFlatIndex(currentFlatPageIndex);
    if (currentPage == null) return;

    cancelAutoplaySequence(disableAutoplay: true);
    clearAudioPlaybackKeys();
    await pauseAudio();
    if (!mounted) return;

    final currentFlatIndex = currentFlatPageIndex;
    setTopControlsRevealToken(topControlsRevealToken + 1);
    transformationController.value = overviewMatrixForPage(currentPage);
    setStateSafe(() {
      setOverviewOriginFlatIndex(currentFlatIndex);
      setOverviewSelectedFlatIndex(currentFlatIndex);
      setOverviewPinchCloseTriggered(false);
      setOverviewGestureLock(false);
      setOverviewPendingCloseFlatIndex(null);
      setShowTopControls(false);
      setShowOverviewLayer(true);
      setIsOverviewMode(true);
      setIsOverviewClosing(false);
      setShowOverviewExitButton(true);
      setShowPinned(false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isOverviewLayerShown()) return;
      unawaited(
        animateOverviewMatrix(
          overviewMatrixForPage(currentPage, scale: overviewPreviewScale),
          curve: Curves.easeInOutCubic,
        ),
      );
    });
  }

  static Future<void> closeOverviewMode({
    required bool showOverviewLayer,
    required bool isAnimatingOverviewMatrix,
    required bool applySelection,
    required int overviewSelectedFlatIndex,
    required int overviewOriginFlatIndex,
    required StagePageReference? Function(int flatIndex) pageForFlatIndex,
    required void Function(bool value) setScaleGestureTriggered,
    required void Function(bool value) setOverviewPinchCloseTriggered,
    required void Function(int? value) setOverviewPendingCloseFlatIndex,
    required void Function(VoidCallback fn) setStateSafe,
    required void Function(bool value) setShowOverviewLayer,
    required void Function(bool value) setIsOverviewMode,
    required void Function(bool value) setIsOverviewClosing,
    required void Function(bool value) setShowOverviewExitButton,
    required void Function(bool value) setOverviewGestureLock,
    required void Function(bool value) setShowPinned,
    required VoidCallback scheduleTopControlsReveal,
    required Future<void> Function(
      Matrix4 target, {
      Duration duration,
      Curve curve,
    })
    animateOverviewMatrix,
    required Matrix4 Function(StagePageReference page, {double scale})
    overviewMatrixForPage,
    required bool mounted,
    required int currentRakaatIndex,
    required int clampedStepIndex,
    required VoidCallback jumpToTop,
    required Future<void> Function(
      int rakaatIndex,
      int stepIndex, {
      bool playIfAutoplay,
      int direction,
      bool animateStepTransition,
    })
    selectRakaatAndStep,
  }) async {
    if (!showOverviewLayer || isAnimatingOverviewMatrix) return;
    setScaleGestureTriggered(false);
    setOverviewPinchCloseTriggered(false);
    setOverviewPendingCloseFlatIndex(null);

    final targetFlatIndex = applySelection
        ? overviewSelectedFlatIndex
        : overviewOriginFlatIndex;
    final selected = pageForFlatIndex(targetFlatIndex);
    if (selected == null) {
      setStateSafe(() {
        setShowOverviewLayer(false);
        setIsOverviewMode(false);
        setIsOverviewClosing(false);
        setShowOverviewExitButton(false);
        setOverviewGestureLock(false);
      });
      scheduleTopControlsReveal();
      return;
    }

    setStateSafe(() {
      setIsOverviewClosing(true);
      setShowOverviewExitButton(false);
      setShowPinned(false);
    });
    await animateOverviewMatrix(
      overviewMatrixForPage(selected),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;

    final returnsToCurrentPage =
        selected.rakaatIndex == currentRakaatIndex &&
        selected.stepIndex == clampedStepIndex;
    if (returnsToCurrentPage) {
      jumpToTop();
    }

    if (applySelection && !returnsToCurrentPage) {
      final direction = selected.rakaatIndex == currentRakaatIndex
          ? (selected.stepIndex >= clampedStepIndex ? 1 : -1)
          : (selected.rakaatIndex >= currentRakaatIndex ? 1 : -1);
      await selectRakaatAndStep(
        selected.rakaatIndex,
        selected.stepIndex,
        playIfAutoplay: false,
        direction: direction,
        animateStepTransition: false,
      );
    }
    if (!mounted) return;

    setStateSafe(() {
      setShowOverviewLayer(false);
      setIsOverviewMode(false);
      setIsOverviewClosing(false);
      setShowOverviewExitButton(false);
      setShowPinned(false);
      setOverviewGestureLock(false);
    });
    scheduleTopControlsReveal();
  }

  static void scheduleTopControlsReveal({
    required int nextToken,
    required void Function(int value) setTopControlsRevealToken,
    required bool Function() mounted,
    required int Function() topControlsRevealToken,
    required bool Function() showOverviewLayer,
    required bool Function() showTopControls,
    required void Function(VoidCallback fn) setStateSafe,
    required void Function(bool value) setShowTopControls,
  }) {
    setTopControlsRevealToken(nextToken);
    Future<void>.delayed(Duration.zero, () {
      if (!mounted()) return;
      if (nextToken != topControlsRevealToken()) return;
      if (showOverviewLayer()) return;
      if (showTopControls()) return;
      setStateSafe(() => setShowTopControls(true));
    });
  }

  static Future<void> closeOverviewFromPinch({
    required bool showOverviewLayer,
    required bool isAnimatingOverviewMatrix,
    required int? overviewPendingCloseFlatIndex,
    required int overviewSelectedFlatIndex,
    required StagePageReference? Function(int flatIndex) pageForFlatIndex,
    required bool mounted,
    required void Function(VoidCallback fn) setStateSafe,
    required void Function(int value) setOverviewSelectedFlatIndex,
    required TransformationController transformationController,
    required Matrix4 Function(StagePageReference page, {double scale})
    overviewMatrixForPage,
    required double overviewPreviewScale,
    required void Function(bool value) setOverviewPinchCloseTriggered,
    required void Function(bool value) setOverviewGestureLock,
    required void Function(int? value) setOverviewPendingCloseFlatIndex,
    required Future<void> Function({bool applySelection}) closeOverviewMode,
  }) async {
    if (!showOverviewLayer || isAnimatingOverviewMatrix) return;
    final targetFlatIndex =
        overviewPendingCloseFlatIndex ?? overviewSelectedFlatIndex;
    final selected = pageForFlatIndex(targetFlatIndex);
    if (selected == null) return;

    if (overviewSelectedFlatIndex != targetFlatIndex && mounted) {
      setStateSafe(() => setOverviewSelectedFlatIndex(targetFlatIndex));
    }
    transformationController.value = overviewMatrixForPage(
      selected,
      scale: overviewPreviewScale,
    );
    setOverviewPinchCloseTriggered(true);
    setOverviewGestureLock(true);
    setOverviewPendingCloseFlatIndex(null);
    await closeOverviewMode(applySelection: true);
  }

  static Future<void> handleOverviewCardTap({
    required StagePageReference page,
    required List<StagePageReference> allStagePages,
    required void Function(VoidCallback fn) setStateSafe,
    required void Function(int value) setOverviewSelectedFlatIndex,
    required Future<void> Function({bool applySelection}) closeOverviewMode,
  }) async {
    final flatIndex = allStagePages.indexWhere(
      (item) =>
          item.rakaatIndex == page.rakaatIndex &&
          item.stepIndex == page.stepIndex,
    );
    if (flatIndex < 0) return;
    setStateSafe(() => setOverviewSelectedFlatIndex(flatIndex));
    await closeOverviewMode(applySelection: true);
  }
}
