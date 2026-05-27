import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/l10n/app_localization.dart';
import '../models/rakaat_models.dart';
import '../models/stage_step_screen_models.dart';

class StageStepScreenFlowHelper {
  static Widget animateAppear({
    required bool contentAppeared,
    required Widget child,
  }) {
    return AnimatedOpacity(
      opacity: contentAppeared ? 1 : 0,
      duration: const Duration(milliseconds: 960),
      curve: Curves.easeOut,
      child: child,
    );
  }

  static Widget animateRakaat(Widget child) => child;

  static Widget animateStepTransition({
    required int token,
    required int direction,
    required Widget child,
  }) {
    final dxDirection = direction >= 0 ? 1.0 : -1.0;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(token),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 510),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Transform.translate(
          offset: Offset(dxDirection * 34.w * (1 - value), 0),
          child: animatedChild,
        );
      },
      child: child,
    );
  }

  static DisplayedStepProgress displayStepProgressFor({
    required List<RakaatData> rakaats,
    required String prayerCode,
    required int rakaatIndex,
    required int stepIndex,
    required List<int> Function(int rakaatIndex) stepOrderIndexesForRakaatIndex,
  }) {
    if (rakaats.isEmpty) {
      return const DisplayedStepProgress(current: 1, total: 1);
    }
    final orderIndexes = stepOrderIndexesForRakaatIndex(rakaatIndex);
    if (orderIndexes.isEmpty) {
      return const DisplayedStepProgress(current: 1, total: 1);
    }
    final clampedStep = stepIndex.clamp(0, orderIndexes.length - 1);
    final currentOrderIndex = orderIndexes[clampedStep];
    final rakaatNumber =
        rakaats[rakaatIndex.clamp(0, rakaats.length - 1)].number;
    // In every prayer the very first rakaat has 3 opening dhikrs:
    // Takbir → Dua Istiftah → Istiaza (protection from devil). Show them
    // as 1/3, 2/3, 3/3, then the rest of the rakaat as its own block.
    if (rakaatNumber == 1) {
      if (currentOrderIndex <= 3) {
        return DisplayedStepProgress(current: currentOrderIndex, total: 3);
      }
      final totalUnique = orderIndexes.toSet().length;
      final remainingTotal = (totalUnique - 3).clamp(1, 1 << 30);
      return DisplayedStepProgress(
        current: (currentOrderIndex - 3).clamp(1, remainingTotal),
        total: remainingTotal,
      );
    }
    return DisplayedStepProgress(
      current: clampedStep + 1,
      total: orderIndexes.length,
    );
  }

  static Future<void> animateStepTransitionTo({
    required int stepIndex,
    required int rakaatIndex,
    required List<int> currentStepOrderIndexes,
    required int direction,
    required Future<void> Function(
      int rakaatIndex,
      int stepIndex, {
      bool playIfAutoplay,
      int direction,
    })
    selectRakaatAndStep,
  }) async {
    if (currentStepOrderIndexes.isEmpty) return;
    final nextStep = stepIndex.clamp(0, currentStepOrderIndexes.length - 1);
    await selectRakaatAndStep(
      rakaatIndex,
      nextStep,
      playIfAutoplay: false,
      direction: direction,
    );
  }

  static Future<void> animateRakaatTransitionTo({
    required int index,
    required int stepIndex,
    required int direction,
    required Future<void> Function(
      int rakaatIndex,
      int stepIndex, {
      bool playIfAutoplay,
      int direction,
    })
    selectRakaatAndStep,
  }) async {
    await selectRakaatAndStep(
      index,
      stepIndex,
      playIfAutoplay: false,
      direction: direction,
    );
  }

  static Future<void> nextStep({
    required BuildContext context,
    required bool isStageTransitioning,
    required List<int> currentStepOrderIndexes,
    required int clampedStepIndex,
    required List<RakaatData> rakaats,
    required int rakaatIndex,
    required void Function() triggerLightHaptic,
    required Future<void> Function(int stepIndex, {required int direction})
    animateStepTransitionTo,
    required Future<void> Function(
      int index, {
      required int stepIndex,
      required int direction,
    })
    animateRakaatTransitionTo,
  }) async {
    if (currentStepOrderIndexes.isEmpty || isStageTransitioning) return;
    triggerLightHaptic();
    if (clampedStepIndex < currentStepOrderIndexes.length - 1) {
      await animateStepTransitionTo(clampedStepIndex + 1, direction: 1);
      return;
    }
    if (rakaats.isEmpty) return;
    final next = (rakaatIndex + 1).clamp(0, rakaats.length - 1);
    if (next == rakaatIndex) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('stage.prayerCompleted'))),
      );
      return;
    }
    await animateRakaatTransitionTo(next, stepIndex: 0, direction: 1);
  }

  static Future<void> prevStep({
    required bool isStageTransitioning,
    required List<int> currentStepOrderIndexes,
    required int clampedStepIndex,
    required List<RakaatData> rakaats,
    required int rakaatIndex,
    required int Function(int rakaatIndex) stepCountForRakaat,
    required void Function() triggerLightHaptic,
    required Future<void> Function(int stepIndex, {required int direction})
    animateStepTransitionTo,
    required Future<void> Function(
      int index, {
      required int stepIndex,
      required int direction,
    })
    animateRakaatTransitionTo,
  }) async {
    if (currentStepOrderIndexes.isEmpty || isStageTransitioning) return;
    triggerLightHaptic();
    if (clampedStepIndex > 0) {
      await animateStepTransitionTo(clampedStepIndex - 1, direction: -1);
      return;
    }
    if (rakaats.isEmpty) return;
    final prev = (rakaatIndex - 1).clamp(0, rakaats.length - 1);
    if (prev == rakaatIndex) return;
    final prevStepCount = stepCountForRakaat(prev);
    final prevStepIndex = prevStepCount == 0 ? 0 : prevStepCount - 1;
    await animateRakaatTransitionTo(
      prev,
      stepIndex: prevStepIndex,
      direction: -1,
    );
  }

  static void handleHorizontalDragEnd({
    required DragEndDetails details,
    required bool isOverviewMode,
    required double horizontalSwipeVelocityThreshold,
    required Future<void> Function() nextStep,
    required Future<void> Function() prevStep,
  }) {
    if (isOverviewMode) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -horizontalSwipeVelocityThreshold) {
      unawaited(nextStep());
      return;
    }
    if (velocity >= horizontalSwipeVelocityThreshold) {
      unawaited(prevStep());
    }
  }

  static List<StageStepGroup> groupedStepsForRakaat({
    required List<RakaatData> rakaats,
    required int rakaatIndex,
  }) {
    if (rakaats.isEmpty) return const [];
    final index = rakaatIndex.clamp(0, rakaats.length - 1);
    final byOrder = <int, RakaatStep>{};
    for (final step in rakaats[index].steps) {
      byOrder.putIfAbsent(step.orderIndex, () => step);
    }
    final sorted = byOrder.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted
        .map((entry) => StageStepGroup(title: entry.value.title))
        .toList(growable: false);
  }

  static Future<void> jumpToRakaatAndStep({
    required List<RakaatData> rakaats,
    required int currentRakaatIndex,
    required int currentStepIndex,
    required int rakaatIndex,
    required int stepIndex,
    required List<StageStepGroup> Function(int rakaatIndex)
    groupedStepsForRakaat,
    required Future<void> Function(int stepIndex, {required int direction})
    animateStepTransitionTo,
    required Future<void> Function(
      int index, {
      required int stepIndex,
      required int direction,
    })
    animateRakaatTransitionTo,
  }) async {
    if (rakaats.isEmpty) return;
    final nextRakaat = rakaatIndex.clamp(0, rakaats.length - 1);
    final steps = groupedStepsForRakaat(nextRakaat);
    if (steps.isEmpty) return;
    final nextStep = stepIndex.clamp(0, steps.length - 1);
    if (nextRakaat == currentRakaatIndex && nextStep == currentStepIndex) {
      return;
    }
    if (nextRakaat == currentRakaatIndex) {
      await animateStepTransitionTo(
        nextStep,
        direction: nextStep >= currentStepIndex ? 1 : -1,
      );
      return;
    }
    await animateRakaatTransitionTo(
      nextRakaat,
      stepIndex: nextStep,
      direction: nextRakaat >= currentRakaatIndex ? 1 : -1,
    );
  }
}
