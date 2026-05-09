import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../stage/animations/stage_drag_carousel.dart';
import '../../../stage/parts/stage_bottom_button.dart';
import '../../../stage/parts/stage_card.dart';
import '../../../stage/parts/stage_progress_bar.dart';
import '../../../stage/parts/stage_top_bar.dart';
import '../models/ablution_manifest_models.dart';
import 'ablution_layout_data.dart';

Widget buildAblutionPageContent({
  required BuildContext context,
  required AblutionStepManifest step,
  required int stepNumber,
  required int totalSteps,
  required double progress,
  required String title,
  required bool showTopControls,
  required GlobalKey stageButtonKey,
  required GlobalKey progressKey,
  required GlobalKey onboardingHighlightKey,
  required Widget Function(Widget child) animateStepTransition,
  required String Function(AblutionStepManifest step) stepImageAsset,
  required bool Function(AblutionStepManifest step) isStepAudioPlaying,
  required String Function(AblutionStepManifest step)
  localizedStepTransliteration,
  required VoidCallback onBack,
  required VoidCallback onStage,
  required VoidCallback onPrev,
  required VoidCallback onNext,
  required Future<void> Function() onProgrammaticPrev,
  required Future<void> Function() onProgrammaticNext,
  required VoidCallback onOpenOverview,
  required void Function(AblutionStepManifest step) onToggleStepAudio,
  AblutionStepManifest? prevGhostStep,
  AblutionStepManifest? nextGhostStep,
  VoidCallback? onCarouselDragStarted,
  ScrollController? scrollController,
}) {
  final carouselController = StageDragCarouselController();
  final hasPrevStep = stepNumber > 1;
  final hasNextStep = stepNumber < totalSteps;
  Widget buildStepContent(
    BuildContext context,
    AblutionStepManifest contentStep, {
    required double navButtonsOpacity,
    required GlobalKey? stepCardKey,
    required GlobalKey? textCardKey,
    required bool interactive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) {
            final card = _AblutionStepCard(
              step: contentStep,
              cardTextSize: AblutionLayoutData.of(context).cardTextSize,
              imageAsset: stepImageAsset(contentStep),
              highlightKey: stepCardKey,
            );
            return card;
          },
        ),
        if (contentStep.text != null) ...[
          SizedBox(height: 12.h),
          Pressable(
            onTap: interactive ? () => onToggleStepAudio(contentStep) : null,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: KeyedSubtree(
              key: textCardKey,
              child: _AblutionTextCard(
                step: contentStep,
                cardTextSize: AblutionLayoutData.of(context).cardTextSize,
                isPlaying: interactive && isStepAudioPlaying(contentStep),
                transliteration: localizedStepTransliteration(contentStep),
              ),
            ),
          ),
        ],
        SizedBox(height: 26.h),
        TweenAnimationBuilder<double>(
          key: ValueKey<String>('ablution-nav-${contentStep.id}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value * navButtonsOpacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.96 + (0.04 * value),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  opacity: hasPrevStep ? 1.0 : 0.5,
                  child: StageBottomButton(
                    variant: StageBottomButtonVariant.secondary,
                    label: context.t('common.back'),
                    icon: 'assets/icons/arrow-left.svg',
                    onTap: interactive && hasPrevStep
                        ? () => unawaited(carouselController.animatePrev())
                        : null,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  opacity: hasNextStep ? 1.0 : 0.5,
                  child: StageBottomButton(
                    variant: StageBottomButtonVariant.primary,
                    label: context.t('common.next'),
                    icon: 'assets/icons/arrow-right.svg',
                    onTap: interactive && hasNextStep
                        ? () => unawaited(carouselController.animateNext())
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  return Builder(
    builder: (context) {
      final layout = AblutionLayoutData.of(context);
      final topContentPadding = layout.topInset;
      final bottomInset = layout.bottomInset;
      return ListView(
        controller: scrollController,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: topContentPadding,
          bottom: 24 + bottomInset,
        ),
        children: [
          IgnorePointer(
            ignoring: !showTopControls,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              scale: showTopControls ? 1 : 0.9,
              alignment: Alignment.center,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
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
          KeyedSubtree(
            key: progressKey,
            child: Pressable(
              onTap: onOpenOverview,
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: StageProgressBlock(
                title: title,
                stepIndex: stepNumber,
                totalSteps: totalSteps,
                progress: progress.clamp(0.0, 1.0),
                showRakaats: false,
                animateProgress: false,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          StageDragCarousel(
            controller: carouselController,
            canGoNext: hasNextStep,
            canGoPrev: hasPrevStep,
            onNext: () async => onNext(),
            onPrev: () async => onPrev(),
            onProgrammaticNext: onProgrammaticNext,
            onProgrammaticPrev: onProgrammaticPrev,
            onDragStarted: onCarouselDragStarted,
            childBuilder: (context, dragProgress) {
              final delayedProgress = ((dragProgress - 0.5) / 0.5).clamp(
                0.0,
                1.0,
              );
              final navButtonsOpacity = (1 - delayedProgress).clamp(0.0, 1.0);
              return animateStepTransition(
                buildStepContent(
                  context,
                  step,
                  navButtonsOpacity: navButtonsOpacity,
                  stepCardKey: step.text == null
                      ? onboardingHighlightKey
                      : null,
                  textCardKey: step.text != null
                      ? onboardingHighlightKey
                      : null,
                  interactive: true,
                ),
              );
            },
            prevGhost: prevGhostStep == null
                ? null
                : buildStepContent(
                    context,
                    prevGhostStep,
                    navButtonsOpacity: 0,
                    stepCardKey: null,
                    textCardKey: null,
                    interactive: false,
                  ),
            nextGhost: nextGhostStep == null
                ? null
                : buildStepContent(
                    context,
                    nextGhostStep,
                    navButtonsOpacity: 0,
                    stepCardKey: null,
                    textCardKey: null,
                    interactive: false,
                  ),
          ),
        ],
      );
    },
  );
}

class _AblutionStepCard extends StatelessWidget {
  const _AblutionStepCard({
    required this.step,
    required this.cardTextSize,
    required this.imageAsset,
    this.highlightKey,
  });

  final AblutionStepManifest step;
  final double cardTextSize;
  final String imageAsset;
  final GlobalKey? highlightKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final child = StageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 244.h,
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(AppRadii.inner),
            ),
            child: Center(
              child: SvgPicture.asset(
                imageAsset,
                width: 220.h,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => SizedBox(width: 250, height: 250),
              ),
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            context.t(step.titleKey),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            context.t(step.descriptionKey),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
    final key = highlightKey;
    return key == null ? child : KeyedSubtree(key: key, child: child);
  }
}

class _AblutionTextCard extends StatelessWidget {
  const _AblutionTextCard({
    required this.step,
    required this.cardTextSize,
    required this.isPlaying,
    required this.transliteration,
  });

  final AblutionStepManifest step;
  final double cardTextSize;
  final bool isPlaying;
  final String transliteration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = step.text!;
    return StageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(AppRadii.inner),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 26.w,
                  height: 26.w,
                  child: Center(
                    child: SvgPicture.asset(
                      isPlaying
                          ? 'assets/icons/pause.svg'
                          : 'assets/icons/play.svg',
                      colorFilter: ColorFilter.mode(
                        colors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    text.arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    textScaler: TextScaler.noScaling,
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            transliteration,
            style: TextStyle(
              fontSize: cardTextSize.sp,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            context.t(text.translationKey),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
