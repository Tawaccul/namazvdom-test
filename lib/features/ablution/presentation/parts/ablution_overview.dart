import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../stage/parts/stage_card.dart';
import '../../../stage/parts/stage_overview_layer.dart';
import '../../../stage/parts/stage_overview_page_builder.dart';
import '../../../stage/parts/stage_progress_bar.dart';
import '../../../stage/parts/stage_step_image.dart';
import '../models/ablution_manifest_models.dart';

Widget buildAblutionOverviewLayer({
  required BuildContext context,
  required AblutionManifest manifest,
  required String title,
  required List<AblutionOverviewPageReference> pages,
  required double pageHeight,
  required Size cardSize,
  required Size canvasSize,
  required TransformationController transformationController,
  required GestureScaleStartCallback onInteractionStart,
  required GestureScaleUpdateCallback onInteractionUpdate,
  required GestureScaleEndCallback onInteractionEnd,
  required bool overviewGestureLock,
  required double overviewDragFriction,
  required double overviewPreviewScale,
  required Offset Function(int flatIndex) cardPositionFor,
  required Future<void> Function(AblutionOverviewPageReference page) onPageTap,
  required Widget Function(AblutionOverviewPageReference page) pageBuilder,
}) {
  if (pages.isEmpty) return const SizedBox.shrink();
  return StageOverviewLayer<AblutionOverviewPageReference>(
    transformationController: transformationController,
    onInteractionStart: onInteractionStart,
    onInteractionUpdate: onInteractionUpdate,
    onInteractionEnd: onInteractionEnd,
    panEnabled: !overviewGestureLock,
    interactionEndFrictionCoefficient: overviewDragFriction,
    minScale: overviewPreviewScale,
    maxScale: 1,
    canvasSize: canvasSize,
    pages: pages,
    cardSize: cardSize,
    pagePositionFor: (page) => cardPositionFor(page.stepIndex),
    onPageTap: (page) => unawaited(onPageTap(page)),
    pageBuilder: pageBuilder,
  );
}

Widget buildAblutionOverviewPage({
  required BuildContext context,
  required AblutionOverviewPageReference page,
  required AblutionManifest manifest,
  required String title,
  required double pageHeight,
  required double topInset,
  required double cardTextSize,
  required ScrollController pageScrollController,
  required bool shouldScheduleOverflowCheck,
  required bool mounted,
  required void Function(int pageId, bool hasOverflow) setOverviewOverflow,
  required String Function(AblutionStepManifest step) stepImageAsset,
  required String Function(AblutionStepManifest step) localizedStepTransliteration,
}) {
  final pageId = page.stepIndex;
  final step = manifest.steps[page.stepIndex];
  final stepNumber = page.stepIndex + 1;
  final totalSteps = manifest.steps.length;
  final progress = totalSteps == 0 ? 0.0 : stepNumber / totalSteps;

  final progressBlock = StageProgressBlock(
    title: title,
    stepIndex: stepNumber,
    totalSteps: totalSteps,
    progress: progress,
    showRakaats: false,
    animateProgress: false,
  );

  final stepCard = StageStepCard(
    imageWidget: StageStepImage(
      stepImageAsset: stepImageAsset(step),
      fallbackStepImageAsset: stepImageAsset(step),
    ),
    title: context.t(step.titleKey),
    description: context.t(step.descriptionKey),
    textSize: cardTextSize,
  );

  final extraCards = [
    if (step.text != null)
      _AblutionOverviewTextCard(
        step: step,
        transliteration: localizedStepTransliteration(step),
        cardTextSize: cardTextSize,
      ),
  ];

  return StageOverviewPage(
    pageHeight: pageHeight,
    topInset: topInset,
    pageId: pageId,
    progressBlock: progressBlock,
    stepCard: stepCard,
    extraCards: extraCards,
    scrollController: pageScrollController,
    shouldScheduleOverflowCheck:
        shouldScheduleOverflowCheck && mounted,
    setOverviewOverflow: setOverviewOverflow,
  );
}

class _AblutionOverviewTextCard extends StatelessWidget {
  const _AblutionOverviewTextCard({
    required this.step,
    required this.transliteration,
    required this.cardTextSize,
  });

  final AblutionStepManifest step;
  final String transliteration;
  final double cardTextSize;

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
                      'assets/icons/play.svg',
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
