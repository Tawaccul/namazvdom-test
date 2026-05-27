import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/text/capitalize.dart';
import '../../../stage/parts/stage_card.dart';
import '../../../stage/parts/stage_overview_layer.dart';
import '../../../stage/parts/stage_progress_bar.dart';
import '../models/ablution_manifest_models.dart';
import 'ablution_layout_data.dart';

Widget buildAblutionOverviewLayer({
  required BuildContext context,
  required AblutionManifest manifest,
  required String title,
  required List<AblutionOverviewPageReference> pages,
  required double pageHeight,
  required Size cardSize,
  required Size canvasSize,
  required double canvasInset,
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
    canvasInset: canvasInset,
    pages: pages,
    cardSize: cardSize,
    pagePositionFor: (page) => cardPositionFor(page.stepIndex),
    onPageTap: (page) => onPageTap(page),
    pageBuilder: pageBuilder,
  );
}

Widget buildAblutionOverviewPage({
  required BuildContext context,
  required AblutionOverviewPageReference page,
  required AblutionManifest manifest,
  required String title,
  required double pageHeight,
  required ScrollController pageScrollController,
  required bool shouldScheduleOverflowCheck,
  required bool mounted,
  required void Function(int pageId, bool hasOverflow) setOverviewOverflow,
  required String Function(AblutionStepManifest step) stepImageAsset,
  required String Function(AblutionStepManifest step)
  localizedStepTransliteration,
}) {
  final pageId = page.stepIndex;
  if (shouldScheduleOverflowCheck) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pageScrollController.hasClients) return;
      setOverviewOverflow(
        pageId,
        pageScrollController.position.maxScrollExtent > 0.5,
      );
    });
  }
  final step = manifest.steps[page.stepIndex];
  final stepNumber = page.stepIndex + 1;
  final progress = stepNumber / math.max(manifest.steps.length, 1);
  return SizedBox(
    height: pageHeight,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: Builder(
          builder: (context) {
            final topInset = AblutionLayoutData.of(context).topInset;
            return NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                setOverviewOverflow(
                  pageId,
                  notification.metrics.maxScrollExtent > 0.5,
                );
                return false;
              },
              child: SingleChildScrollView(
                controller: pageScrollController,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: topInset + 5.h,
                  bottom: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StageProgressBlock(
                      title: title,
                      stepIndex: stepNumber,
                      totalSteps: manifest.steps.length,
                      progress: progress,
                      showRakaats: false,
                      animateProgress: false,
                    ),
                    SizedBox(height: 14.h),
                    _AblutionOverviewStepCard(
                      step: step,
                      imageAsset: stepImageAsset(step),
                    ),
                    if (step.text != null) ...[
                      SizedBox(height: 12.h),
                      _AblutionOverviewTextCard(
                        step: step,
                        transliteration: localizedStepTransliteration(step),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _AblutionOverviewStepCard extends StatelessWidget {
  const _AblutionOverviewStepCard({
    required this.step,
    required this.imageAsset,
  });

  final AblutionStepManifest step;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardTextSize = AblutionLayoutData.of(context).cardTextSize;
    return StageCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                width: 220.w,
                fit: BoxFit.contain,
                placeholderBuilder: (_) =>
                    SizedBox(width: 250, height: 250),
              ),
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            context.t(step.titleKey),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              fontWeight: FontWeight.w600,
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
  }
}

class _AblutionOverviewTextCard extends StatelessWidget {
  const _AblutionOverviewTextCard({
    required this.step,
    required this.transliteration,
  });

  final AblutionStepManifest step;
  final String transliteration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardTextSize = AblutionLayoutData.of(context).cardTextSize;
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
            capitalizeFirst(transliteration),
            style: TextStyle(
              fontSize: cardTextSize.sp,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            capitalizeFirst(context.t(text.translationKey)),
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
