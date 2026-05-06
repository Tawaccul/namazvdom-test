import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/ui_kit/app_button.dart';
import '../../../core/widgets/pressable.dart';
import '../animations/stage_drag_carousel.dart';
import '../animations/stage_ghost_step_card.dart';
import '../animations/stage_neighbor_step_bundle.dart';
import '../models/rakaat_models.dart';
import '../models/stage_step_screen_models.dart';
import 'stage_progress_bar.dart';
import 'stage_step_content_section.dart';
import 'stage_step_image.dart';
import 'stage_step_screen_scaffold.dart';

Widget buildStageStepScreenBody({
  required BuildContext context,
  required Color backgroundColor,
  required bool allowExitPop,
  required bool showOverviewLayer,
  required bool isOverviewClosing,
  required bool showTopBlur,
  required bool isOverviewMode,
  required bool showPinned,
  required bool showOverviewExitButton,
  required bool showTopControls,
  required bool showOnboarding,
  required GestureDragEndCallback onHorizontalDragEnd,
  required GestureTapCallback onDoubleTap,
  required GestureScaleStartCallback onScaleStart,
  required GestureScaleUpdateCallback onScaleUpdate,
  required GestureScaleEndCallback onScaleEnd,
  required ScrollController mainScrollController,
  required TransformationController transformationController,
  required GestureScaleStartCallback onOverviewInteractionStart,
  required GestureScaleUpdateCallback onOverviewInteractionUpdate,
  required GestureScaleEndCallback onOverviewInteractionEnd,
  required bool overviewPanEnabled,
  required double overviewDragFriction,
  required double overviewMinScale,
  required Size overviewCanvasSize,
  required List<StagePageReference> overviewPages,
  required Size overviewCardSize,
  required Offset Function(StagePageReference page) pagePositionFor,
  required Future<void> Function(StagePageReference page) onPageTap,
  required Widget Function(StagePageReference page) pageBuilder,
  required double topContentPadding,
  required VoidCallback onBack,
  required VoidCallback onStage,
  required GlobalKey stageButtonKey,
  required Widget Function(Widget child) animateAppear,
  required VoidCallback onOpenOverview,
  required GlobalKey progressKey,
  required String prayerTitle,
  required int totalRakaats,
  required int rakaatIndex,
  required int stepIndex,
  required int totalSteps,
  required double stepProgress,
  required Widget Function(Widget child) animateStepTransition,
  required Widget Function(Widget child) animateRakaat,
  required String stepTitle,
  required String movementDescription,
  required double cardTextSize,
  required Color softColor,
  required Color textPrimaryColor,
  required Color textSecondaryColor,
  required String currentStepImageAsset,
  required String fallbackStepImageAsset,
  required bool hasAdditionalSurahSelector,
  required List<RakaatSurahOption> additionalSurahOptions,
  required int selectedAdditionalSurahIndex,
  required Future<void> Function(int optionIndex) onSelectAdditionalSurah,
  required List<RakaatStep> currentStepEntries,
  required int additionalSurahAnimationToken,
  required String Function(int index) entryKeyFor,
  required GlobalKey Function(int index) keyForEntry,
  required String? playingStepKey,
  required bool isAudioPlaying,
  required double audioProgress,
  required void Function(int index) onAyahTap,
  required String? errorText,
  required bool navButtonsVisible,
  required bool hasPrevStageStep,
  required bool hasNextStageStep,
  required bool canGoBack,
  required bool canGoNext,
  required Future<void> Function() onPrevStep,
  required Future<void> Function() onNextStep,
  required int onboardingStepIndex,
  required VoidCallback onOnboardingNext,
  required GlobalKey selectedAyahCardKey,
  required double topControlInset,
  required VoidCallback onOverviewExit,
  StageNeighborStepBundle? prevGhost,
  StageNeighborStepBundle? nextGhost,
  VoidCallback? onCarouselDragStarted,
}) {
  final progressCard = animateAppear(
    Pressable(
      onTap: onOpenOverview,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: KeyedSubtree(
        key: progressKey,
        child: StageProgressBlock(
          title: context.t(
            'stage.prayerTitleWithRakaats',
            namedArgs: {'title': prayerTitle, 'count': '$totalRakaats'},
          ),
          rakaatIndex: rakaatIndex,
          totalRakaats: totalRakaats,
          stepIndex: stepIndex,
          totalSteps: totalSteps,
          progress: stepProgress.clamp(0.0, 1.0),
          animateProgress: false,
        ),
      ),
    ),
  );

  // Билдер активного контента шага. Получает [dragProgress] (0..1) для
  // плавного скрытия кнопок навигации при свайпе.
  Widget buildStepContent(BuildContext context, double dragProgress) {
    final navOpacity = (1 - dragProgress * 2).clamp(0.0, 1.0);
    return StageStepContentSection(
      animateStepTransition: animateStepTransition,
      animateRakaat: animateRakaat,
      animateAppear: animateAppear,
      stepTitle: stepTitle,
      movementDescription: movementDescription,
      cardTextSize: cardTextSize,
      softColor: softColor,
      textPrimaryColor: textPrimaryColor,
      textSecondaryColor: textSecondaryColor,
      stepImage: StageStepImage(
        stepImageAsset: currentStepImageAsset,
        fallbackStepImageAsset: fallbackStepImageAsset,
      ),
      hasAdditionalSurahSelector: hasAdditionalSurahSelector,
      additionalSurahOptions: additionalSurahOptions,
      selectedAdditionalSurahIndex: selectedAdditionalSurahIndex,
      onSelectAdditionalSurah: onSelectAdditionalSurah,
      currentStepEntries: currentStepEntries,
      additionalSurahAnimationToken: additionalSurahAnimationToken,
      entryKeyFor: entryKeyFor,
      keyForEntry: keyForEntry,
      playingStepKey: playingStepKey,
      isAudioPlaying: isAudioPlaying,
      audioProgress: audioProgress,
      onAyahTap: onAyahTap,
      errorText: errorText,
      navButtonsVisible: navButtonsVisible,
      hasPrevStageStep: hasPrevStageStep,
      hasNextStageStep: hasNextStageStep,
      canGoBack: canGoBack,
      canGoNext: canGoNext,
      backButtonLabel: context.t('common.back'),
      nextButtonLabel: context.t('common.next'),
      onPrevStep: canGoBack ? () => unawaited(onPrevStep()) : null,
      onNextStep: canGoNext ? () => unawaited(onNextStep()) : null,
      navButtonsOpacity: navOpacity,
    );
  }

  Widget? buildGhost(StageNeighborStepBundle? bundle) {
    if (bundle == null) return null;
    return StageGhostStepCard(
      stepTitle: bundle.stepTitle,
      movementDescription: bundle.movementDescription,
      cardTextSize: cardTextSize,
      softColor: softColor,
      textPrimaryColor: textPrimaryColor,
      textSecondaryColor: textSecondaryColor,
      stepImageAsset: bundle.stepImageAsset,
      fallbackStepImageAsset: bundle.fallbackStepImageAsset,
      entries: bundle.entries,
    );
  }

  final stepContentSection = StageDragCarousel(
    canGoNext: hasNextStageStep,
    canGoPrev: hasPrevStageStep,
    onNext: onNextStep,
    onPrev: onPrevStep,
    onDragStarted: onCarouselDragStarted,
    childBuilder: (context, dragProgress) =>
        buildStepContent(context, dragProgress),
    prevGhost: buildGhost(prevGhost),
    nextGhost: buildGhost(nextGhost),
  );

  final overviewExitVariant = Theme.of(context).brightness == Brightness.light
      ? AppButtonVariant.card
      : AppButtonVariant.secondary;

  return StageStepScreenScaffold(
    backgroundColor: backgroundColor,
    allowExitPop: allowExitPop,
    showOverviewLayer: showOverviewLayer,
    isOverviewClosing: isOverviewClosing,
    showTopBlur: showTopBlur,
    isOverviewMode: isOverviewMode,
    showPinned: showPinned,
    showOverviewExitButton: showOverviewExitButton,
    showTopControls: showTopControls,
    showOnboarding: showOnboarding,
    onHorizontalDragEnd: onHorizontalDragEnd,
    onDoubleTap: onDoubleTap,
    onScaleStart: onScaleStart,
    onScaleUpdate: onScaleUpdate,
    onScaleEnd: onScaleEnd,
    mainScrollController: mainScrollController,
    transformationController: transformationController,
    onOverviewInteractionStart: onOverviewInteractionStart,
    onOverviewInteractionUpdate: onOverviewInteractionUpdate,
    onOverviewInteractionEnd: onOverviewInteractionEnd,
    overviewPanEnabled: overviewPanEnabled,
    overviewDragFriction: overviewDragFriction,
    overviewMinScale: overviewMinScale,
    overviewCanvasSize: overviewCanvasSize,
    overviewPages: overviewPages,
    overviewCardSize: overviewCardSize,
    pagePositionFor: pagePositionFor,
    onPageTap: onPageTap,
    pageBuilder: pageBuilder,
    topContentPadding: topContentPadding,
    onBack: onBack,
    onStage: onStage,
    stageButtonKey: stageButtonKey,
    progressCard: progressCard,
    progressCardKey: progressKey,
    stepContentSection: stepContentSection,
    pinnedRakaatIndex: rakaatIndex,
    pinnedTotalRakaats: totalRakaats,
    pinnedStepIndex: stepIndex,
    pinnedTotalSteps: totalSteps,
    pinnedProgress: stepProgress,
    onPinnedTap: onOpenOverview,
    showTopBarPlaceholder: isOverviewClosing && showTopControls,
    topControlInset: topControlInset,
    onOverviewExit: onOverviewExit,
    overviewExitLabel: context.t('common.exit'),
    overviewExitButtonVariant: overviewExitVariant,
    selectedAyahCardKey: selectedAyahCardKey,
    onboardingStepIndex: onboardingStepIndex,
    onOnboardingNext: onOnboardingNext,
  );
}
