import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../stage/parts/stage_bottom_button.dart';
import '../../../stage/parts/stage_card.dart';
import '../../../stage/parts/stage_top_bar.dart';
import '../models/ablution_manifest_models.dart';
import 'ablution_progress_block.dart';

Widget buildAblutionPageContent({
  required BuildContext context,
  required AblutionStepManifest step,
  required int stepNumber,
  required int totalSteps,
  required double progress,
  required double cardTextSize,
  required String title,
  required double topContentPadding,
  required double bottomInset,
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
  required VoidCallback onOpenOverview,
  required void Function(AblutionStepManifest step) onToggleStepAudio,
  ScrollController? scrollController,
}) {
  final hasPrevStep = stepNumber > 1;
  final hasNextStep = stepNumber < totalSteps;
  return ListView(
    controller: scrollController,
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.only(
      top: topContentPadding,
      bottom: 24.h + bottomInset,
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
      SizedBox(height: 20.h),
      KeyedSubtree(
        key: progressKey,
        child: Pressable(
          onTap: onOpenOverview,
          borderRadius: BorderRadius.circular(AppRadii.card.r),
          child: AblutionProgressBlock(
            title: title,
            stepIndex: stepNumber,
            totalSteps: totalSteps,
            progress: progress.clamp(0.0, 1.0),
          ),
        ),
      ),
      SizedBox(height: 12.h),
      animateStepTransition(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AblutionStepCard(
              step: step,
              cardTextSize: cardTextSize,
              imageAsset: stepImageAsset(step),
              highlightKey: step.text == null ? onboardingHighlightKey : null,
            ),
            if (step.text != null) ...[
              SizedBox(height: 12.h),
              Pressable(
                onTap: () => onToggleStepAudio(step),
                borderRadius: BorderRadius.circular(AppRadii.card.r),
                child: KeyedSubtree(
                  key: onboardingHighlightKey,
                  child: _AblutionTextCard(
                    step: step,
                    cardTextSize: cardTextSize,
                    isPlaying: isStepAudioPlaying(step),
                    transliteration: localizedStepTransliteration(step),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      SizedBox(height: 20.h),
      Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              opacity: hasPrevStep ? 1 : 0.5,
              child: StageBottomButton(
                variant: StageBottomButtonVariant.secondary,
                label: context.t('common.back'),
                icon: 'assets/icons/arrow-left.svg',
                onTap: hasPrevStep ? onPrev : null,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              opacity: hasNextStep ? 1 : 0.5,
              child: StageBottomButton(
                variant: StageBottomButtonVariant.primary,
                label: context.t('common.next'),
                icon: 'assets/icons/arrow-right.svg',
                onTap: hasNextStep ? onNext : null,
              ),
            ),
          ),
        ],
      ),
    ],
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
        children: [
          Container(
            height: 260.h,
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(AppRadii.inner.r),
            ),
            child: Center(
              child: SvgPicture.asset(
                imageAsset,
                width: 250.h,
                fit: BoxFit.contain,
                placeholderBuilder: (_) =>
                    SizedBox(width: 250.h, height: 250.h),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            context.t(step.titleKey),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            context.t(step.descriptionKey),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              height: 1.48,
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(AppRadii.inner.r),
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
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w500,
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
          SizedBox(height: 8.h),
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
