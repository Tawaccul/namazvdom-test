import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_radii.dart';
import '../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../app/ui_kit/app_button.dart';
import '../../../core/widgets/pressable.dart';
import '../models/stage_step_screen_models.dart';
import '../stage_onboarding_overlay.dart';
import '../stage_overview_constants.dart';
import 'stage_overview_layer.dart';
import 'stage_pinned_progress.dart';
import 'stage_top_bar.dart';

class StageStepScreenScaffold extends StatelessWidget {
  const StageStepScreenScaffold({
    super.key,
    required this.backgroundColor,
    required this.allowExitPop,
    required this.showOverviewLayer,
    required this.isOverviewClosing,
    required this.showTopBlur,
    required this.isOverviewMode,
    required this.showPinned,
    required this.showOverviewExitButton,
    required this.showTopControls,
    required this.showOnboarding,
    required this.onHorizontalDragEnd,
    required this.onDoubleTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.mainScrollController,
    required this.transformationController,
    required this.onOverviewInteractionStart,
    required this.onOverviewInteractionUpdate,
    required this.onOverviewInteractionEnd,
    required this.overviewPanEnabled,
    required this.overviewDragFriction,
    required this.overviewMinScale,
    required this.overviewCanvasSize,
    required this.overviewPages,
    required this.overviewCardSize,
    required this.pagePositionFor,
    required this.onPageTap,
    required this.pageBuilder,
    required this.topContentPadding,
    required this.onBack,
    required this.onStage,
    required this.stageButtonKey,
    required this.progressCard,
    required this.progressCardKey,
    required this.stepContentSection,
    required this.pinnedRakaatIndex,
    required this.pinnedTotalRakaats,
    required this.pinnedStepIndex,
    required this.pinnedTotalSteps,
    required this.pinnedProgress,
    required this.onPinnedTap,
    required this.showTopBarPlaceholder,
    required this.topControlInset,
    required this.onOverviewExit,
    required this.overviewExitLabel,
    required this.overviewExitButtonVariant,
    required this.selectedAyahCardKey,
    required this.onboardingStepIndex,
    required this.onOnboardingNext,
  });

  final Color backgroundColor;
  final bool allowExitPop;
  final bool showOverviewLayer;
  final bool isOverviewClosing;
  final bool showTopBlur;
  final bool isOverviewMode;
  final bool showPinned;
  final bool showOverviewExitButton;
  final bool showTopControls;
  final bool showOnboarding;

  final GestureDragEndCallback onHorizontalDragEnd;
  final GestureTapCallback onDoubleTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  final ScrollController mainScrollController;
  final TransformationController transformationController;
  final GestureScaleStartCallback onOverviewInteractionStart;
  final GestureScaleUpdateCallback onOverviewInteractionUpdate;
  final GestureScaleEndCallback onOverviewInteractionEnd;
  final bool overviewPanEnabled;
  final double overviewDragFriction;
  final double overviewMinScale;
  final Size overviewCanvasSize;
  final List<StagePageReference> overviewPages;
  final Size overviewCardSize;
  final Offset Function(StagePageReference page) pagePositionFor;
  final Future<void> Function(StagePageReference page) onPageTap;
  final Widget Function(StagePageReference page) pageBuilder;
  final double topContentPadding;
  final VoidCallback onBack;
  final VoidCallback onStage;
  final GlobalKey stageButtonKey;
  final Widget progressCard;
  final GlobalKey progressCardKey;
  final Widget stepContentSection;

  final int pinnedRakaatIndex;
  final int pinnedTotalRakaats;
  final int pinnedStepIndex;
  final int pinnedTotalSteps;
  final double pinnedProgress;
  final VoidCallback onPinnedTap;

  final bool showTopBarPlaceholder;
  final double topControlInset;

  final VoidCallback onOverviewExit;
  final String overviewExitLabel;
  final AppButtonVariant overviewExitButtonVariant;

  final GlobalKey selectedAyahCardKey;
  final int onboardingStepIndex;
  final VoidCallback onOnboardingNext;

  @override
  Widget build(BuildContext context) {
    const pinnedHideDuration = Duration(milliseconds: 260);
    const pinnedFadeDuration = Duration(milliseconds: 220);

    return PopScope(
      canPop: allowExitPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          top: false,
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            onDoubleTap: showOverviewLayer ? null : onDoubleTap,
            onScaleStart: showOverviewLayer ? null : onScaleStart,
            onScaleUpdate: showOverviewLayer ? null : onScaleUpdate,
            onScaleEnd: showOverviewLayer ? null : onScaleEnd,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IgnorePointer(
                      ignoring: showOverviewLayer,
                      child: AppBlurredTopOverlay(
                        visible: showTopBlur && !isOverviewMode,
                        height: MediaQuery.paddingOf(context).top + 20.h,
                        maxBlurSigma: 6,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: SingleChildScrollView(
                            controller: mainScrollController,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            padding: EdgeInsets.only(
                              bottom: 34,
                              top: topContentPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                IgnorePointer(
                                  ignoring: !showTopControls,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    scale: showTopControls ? 1 : 0.9,
                                    alignment: Alignment.center,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      opacity: showTopControls ? 1 : 0,
                                      child: StageTopBar(
                                        onBack: onBack,
                                        onStage: onStage,
                                        stageButtonKey: stageButtonKey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                progressCard,
                                SizedBox(height: 12.h),
                                stepContentSection,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showOverviewLayer)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: isOverviewClosing,
                          child: StageOverviewLayer(
                            transformationController: transformationController,
                            onInteractionStart: onOverviewInteractionStart,
                            onInteractionUpdate: onOverviewInteractionUpdate,
                            onInteractionEnd: onOverviewInteractionEnd,
                            panEnabled: overviewPanEnabled,
                            interactionEndFrictionCoefficient:
                                overviewDragFriction,
                            minScale: overviewMinScale,
                            maxScale: 1,
                            canvasSize: overviewCanvasSize,
                            canvasInset: StageOverviewConstants.overviewCanvasInset,
                            pages: overviewPages,
                            cardSize: overviewCardSize,
                            pagePositionFor: pagePositionFor,
                            onPageTap: (page) => unawaited(onPageTap(page)),
                            pageBuilder: pageBuilder,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!showOverviewLayer)
                  Positioned(
                    left: 14.w,
                    right: 14.w,
                    top: MediaQuery.paddingOf(context).top + 8.h,
                    child: IgnorePointer(
                      ignoring: !showPinned || isOverviewMode,
                      child: AnimatedSlide(
                        offset: showPinned
                            ? Offset.zero
                            : const Offset(0, -0.35),
                        duration: pinnedHideDuration,
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          duration: pinnedFadeDuration,
                          curve: Curves.easeOutCubic,
                          opacity: showPinned ? 1 : 0,
                          child: Pressable(
                            onTap: onPinnedTap,
                            borderRadius: BorderRadius.circular(
                              AppRadii.card,
                            ),
                            child: StagePinnedProgressCard(
                              rakaatIndex: pinnedRakaatIndex,
                              totalRakaats: pinnedTotalRakaats,
                              stepIndex: pinnedStepIndex,
                              totalSteps: pinnedTotalSteps,
                              progress: pinnedProgress.clamp(0.0, 1.0),
                              animateProgress: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showOverviewExitButton)
                  Positioned(
                    left: 14.w,
                    right: 14.w,
                    bottom: MediaQuery.paddingOf(context).bottom + 24,
                    child: IgnorePointer(
                      ignoring: false,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: Offset.zero,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          opacity: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadii.inner,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.08
                                        : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AppButton(
                              label: overviewExitLabel,
                              onPressed: onOverviewExit,
                              variant: overviewExitButtonVariant,
                              size: AppButtonSize.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showTopBarPlaceholder)
                  Positioned(
                    left: 14.w,
                    right: 14.w,
                    top: topControlInset,
                    child: IgnorePointer(
                      ignoring: true,
                      child: StageTopBar(onBack: _noop, onStage: _noop),
                    ),
                  ),
                if (showOnboarding && !showOverviewLayer)
                  Positioned.fill(
                    key: const ValueKey('stage_onboarding_overlay'),
                    child: IgnorePointer(
                      ignoring: false,
                      child: StageOnboardingOverlay(
                        key: const ValueKey('stage_onboarding_overlay_content'),
                        stageButtonKey: stageButtonKey,
                        progressCardKey: progressCardKey,
                        selectedAyahCardKey: selectedAyahCardKey,
                        scrollController: mainScrollController,
                        stepIndex: onboardingStepIndex,
                        onNext: onOnboardingNext,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _noop() {}
