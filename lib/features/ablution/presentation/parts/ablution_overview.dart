import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../stage/parts/stage_card.dart';
import '../models/ablution_manifest_models.dart';
import 'ablution_progress_block.dart';

Widget buildAblutionOverviewLayer({
  required BuildContext context,
  required AblutionManifest manifest,
  required String title,
  required double cardTextSize,
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
  return ColoredBox(
    color: context.colors.background,
    child: InteractiveViewer(
      transformationController: transformationController,
      onInteractionStart: onInteractionStart,
      onInteractionUpdate: onInteractionUpdate,
      onInteractionEnd: onInteractionEnd,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      panEnabled: !overviewGestureLock,
      scaleEnabled: !overviewGestureLock,
      panAxis: PanAxis.horizontal,
      interactionEndFrictionCoefficient: overviewDragFriction,
      minScale: overviewPreviewScale,
      maxScale: 1,
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: Stack(
          children: [
            for (final page in pages)
              _AblutionOverviewCardSlot(
                page: page,
                position: cardPositionFor(page.stepIndex),
                cardSize: cardSize,
                onTap: onPageTap,
                child: pageBuilder(page),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget buildAblutionOverviewPage({
  required BuildContext context,
  required AblutionOverviewPageReference page,
  required AblutionManifest manifest,
  required String title,
  required double cardTextSize,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollMetricsNotification>(
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
                top: MediaQuery.paddingOf(context).top + 21.h,
                bottom: 20.h,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AblutionProgressBlock(
                    title: title,
                    stepIndex: stepNumber,
                    totalSteps: manifest.steps.length,
                    progress: progress,
                  ),
                  SizedBox(height: 12.h),
                  _AblutionOverviewStepCard(
                    step: step,
                    cardTextSize: cardTextSize,
                    imageAsset: stepImageAsset(step),
                  ),
                  if (step.text != null) ...[
                    SizedBox(height: 12.h),
                    _AblutionOverviewTextCard(
                      step: step,
                      cardTextSize: cardTextSize,
                      transliteration: localizedStepTransliteration(step),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AblutionOverviewCardSlot extends StatelessWidget {
  const _AblutionOverviewCardSlot({
    required this.page,
    required this.position,
    required this.cardSize,
    required this.onTap,
    required this.child,
  });

  final AblutionOverviewPageReference page;
  final Offset position;
  final Size cardSize;
  final Future<void> Function(AblutionOverviewPageReference page) onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: cardSize.width,
      height: cardSize.height,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => unawaited(onTap(page)),
          child: IgnorePointer(ignoring: true, child: child),
        ),
      ),
    );
  }
}

class _AblutionOverviewStepCard extends StatelessWidget {
  const _AblutionOverviewStepCard({
    required this.step,
    required this.cardTextSize,
    required this.imageAsset,
  });

  final AblutionStepManifest step;
  final double cardTextSize;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StageCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
  }
}

class _AblutionOverviewTextCard extends StatelessWidget {
  const _AblutionOverviewTextCard({
    required this.step,
    required this.cardTextSize,
    required this.transliteration,
  });

  final AblutionStepManifest step;
  final double cardTextSize;
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
