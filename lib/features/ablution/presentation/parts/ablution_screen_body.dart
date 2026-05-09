import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/ui_kit/app_button.dart';
import '../../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../stage/parts/stage_top_bar.dart';
import '../../../stage/stage_onboarding_overlay.dart';
import '../models/ablution_manifest_models.dart';
import 'ablution_content_freeze_layer.dart';
import 'ablution_layout_data.dart';

Widget buildAblutionScreenBody({
  required BuildContext context,
  required Future<AblutionManifest> manifestFuture,
  required AblutionManifest? currentManifest,
  required void Function(AblutionManifest manifest) onManifestLoaded,
  required bool allowExitPop,
  required bool showOverviewLayer,
  required bool isOverviewClosing,
  required bool showTopBlur,
  required bool showOverviewExitButton,
  required bool showOnboarding,
  required bool showTopControls,
  required int onboardingStepIndex,
  required double topControlInset,
  required double bottomInset,
  required double cardTextSize,
  required Color backgroundColor,
  required Color textPrimaryColor,
  required Color textSecondaryColor,
  required GestureDragEndCallback onHorizontalDragEnd,
  required GestureTapCallback onDoubleTap,
  required GestureScaleStartCallback onScaleStart,
  required GestureScaleUpdateCallback onScaleUpdate,
  required GestureScaleEndCallback onScaleEnd,
  required Widget Function({
    required AblutionStepManifest step,
    required int stepNumber,
    required int totalSteps,
    required double progress,
    required String title,
    required ScrollController scrollController,
    required VoidCallback onBack,
    required VoidCallback onStage,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  })
  buildPageContent,
  required Widget Function({
    required AblutionManifest manifest,
    required String title,
  })
  buildOverviewLayer,
  required AblutionStepManifest Function() currentStep,
  required int clampedStepIndex,
  required int totalSteps,
  required ScrollController scrollController,
  required GlobalKey stageButtonKey,
  required GlobalKey progressKey,
  required GlobalKey onboardingHighlightKey,
  required Future<void> Function() popToHome,
  required Future<void> Function() showStepSelector,
  required Future<void> Function() prevStep,
  required Future<void> Function() nextStep,
  required Future<void> Function({bool applySelection}) closeOverviewMode,
  required VoidCallback onOnboardingNext,
}) {
  return AblutionLayoutData(
    topInset: topControlInset,
    bottomInset: bottomInset,
    cardTextSize: cardTextSize,
    child: PopScope(
      canPop: allowExitPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
        top: false,
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: showOverviewLayer ? null : onHorizontalDragEnd,
          onDoubleTap: showOverviewLayer ? null : onDoubleTap,
          onScaleStart: showOverviewLayer ? null : onScaleStart,
          onScaleUpdate: showOverviewLayer ? null : onScaleUpdate,
          onScaleEnd: showOverviewLayer ? null : onScaleEnd,
          child: FutureBuilder<AblutionManifest>(
            future: manifestFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _AblutionStateMessage(
                  text: context.t('app.loading'),
                  color: textSecondaryColor,
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _AblutionStateMessage(
                  text: context.t('errors.failedLoadAblution'),
                  color: textPrimaryColor,
                  centered: true,
                );
              }

              final manifest = currentManifest ?? snapshot.data!;
              onManifestLoaded(manifest);
              if (manifest.steps.isEmpty) {
                return _AblutionStateMessage(
                  text: context.t('errors.failedLoadAblution'),
                  color: textPrimaryColor,
                );
              }

              final resolvedTotalSteps = manifest.steps.length;
              final stepNumber = clampedStepIndex + 1;
              final progress = stepNumber / resolvedTotalSteps;
              final title = context.t(manifest.titleKey);

              return AppBlurredTopOverlay(
                visible: showTopBlur && !showOverviewLayer,
                height: 104.h,
                maxBlurSigma: 6,
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: showOverviewLayer,
                      child: AblutionContentFreezeLayer(
                        frozen: isOverviewClosing,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: buildPageContent(
                            step: currentStep(),
                            stepNumber: stepNumber,
                            totalSteps: resolvedTotalSteps,
                            progress: progress,
                            title: title,
                            scrollController: scrollController,
                            onBack: () => unawaited(popToHome()),
                            onStage: () => unawaited(showStepSelector()),
                            onPrev: () => unawaited(prevStep()),
                            onNext: () => unawaited(nextStep()),
                          ),
                        ),
                      ),
                    ),
                    if (showOverviewLayer)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: isOverviewClosing,
                          child: buildOverviewLayer(
                            manifest: manifest,
                            title: title,
                          ),
                        ),
                      ),
                    if (showOverviewExitButton)
                      _AblutionOverviewExitButton(
                        onPressed: () => unawaited(closeOverviewMode()),
                      ),
                    if (showOnboarding && !showOverviewLayer)
                      Positioned.fill(
                        key: const ValueKey('ablution_onboarding_overlay'),
                        child: IgnorePointer(
                          ignoring: false,
                          child: StageOnboardingOverlay(
                            key: const ValueKey(
                              'ablution_onboarding_overlay_content',
                            ),
                            stageButtonKey: stageButtonKey,
                            progressCardKey: progressKey,
                            selectedAyahCardKey: onboardingHighlightKey,
                            scrollController: scrollController,
                            stepIndex: onboardingStepIndex,
                            onNext: onOnboardingNext,
                          ),
                        ),
                      ),
                    if (isOverviewClosing && showTopControls)
                      Positioned(
                        left: 16.w,
                        right: 16.w,
                        top: topControlInset,
                        child: IgnorePointer(
                          ignoring: true,
                          child: StageTopBar(onBack: () {}, onStage: () {}),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  ),
  );
}

class _AblutionStateMessage extends StatelessWidget {
  const _AblutionStateMessage({
    required this.text,
    required this.color,
    this.centered = false,
  });

  final String text;
  final Color color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      textAlign: centered ? TextAlign.center : null,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
    return Center(
      child: centered
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: child,
            )
          : child,
    );
  }
}

class _AblutionOverviewExitButton extends StatelessWidget {
  const _AblutionOverviewExitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: MediaQuery.paddingOf(context).bottom + 24,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.inner),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.08
                    : 0.04,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppButton(
          label: context.t('common.exit'),
          onPressed: onPressed,
          variant: Theme.of(context).brightness == Brightness.light
              ? AppButtonVariant.card
              : AppButtonVariant.secondary,
          size: AppButtonSize.medium,
        ),
      ),
    );
  }
}
