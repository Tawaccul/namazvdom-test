import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/l10n/app_localization.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../models/rakaat_models.dart';
import '../models/stage_step_screen_models.dart';
import 'stage_ayah_card.dart';
import 'stage_card.dart';
import 'stage_progress_bar.dart';
import 'stage_step_image.dart';

class StageOverviewPage extends StatelessWidget {
  const StageOverviewPage({
    super.key,
    required this.pageId,
    required this.progressBlock,
    required this.stepCard,
    required this.extraCards,
    required this.topInset,
    this.pageHeight,
    this.scrollController,
    this.shouldScheduleOverflowCheck = false,
    this.setOverviewOverflow,
  });

  final double? pageHeight;
  final double topInset;
  final int pageId;
  final Widget progressBlock;
  final Widget stepCard;
  final List<Widget> extraCards;
  final ScrollController? scrollController;
  final bool shouldScheduleOverflowCheck;
  final void Function(int pageId, bool hasOverflow)? setOverviewOverflow;

  @override
  Widget build(BuildContext context) {
    final controller = scrollController;
    final onOverflow = setOverviewOverflow;
    if (shouldScheduleOverflowCheck && controller != null && onOverflow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.hasClients) return;
        onOverflow(
          pageId,
          controller.position.maxScrollExtent > 0.5,
        );
      });
    }

    final scrollView = NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        onOverflow?.call(
          pageId,
          notification.metrics.maxScrollExtent > 0.5,
        );
        return false;
      },
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: topInset + 5.h, bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            progressBlock,
            SizedBox(height: 14.h),
            stepCard,
            for (final card in extraCards) ...[
              SizedBox(height: 12.h),
              card,
            ],
          ],
        ),
      ),
    );

    final h = pageHeight;
    if (h != null) {
      return SizedBox(
        height: h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: scrollView,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: scrollView,
    );
  }
}

Widget buildStageOverviewPage({
  required BuildContext context,
  required List<RakaatData> rakaats,
  required StagePageReference page,
  required String prayerTitle,
  required double cardTextSize,
  required double topInset,
  double? pageHeight,
  ScrollController? scrollController,
  bool shouldScheduleOverflowCheck = false,
  void Function(int pageId, bool hasOverflow)? setOverviewOverflow,
  required List<int> Function(int rakaatIndex) stepOrderIndexesForRakaatIndex,
  required DisplayedStepProgress Function({
    required int rakaatIndex,
    required int stepIndex,
  }) displayStepProgressFor,
  required List<RakaatStep> Function({
    required int rakaatIndex,
    required int stepIndex,
  }) entriesForPage,
  required List<RakaatStep> Function({
    required int rakaatIndex,
    required int stepIndex,
  }) recitationEntriesForPage,
}) {
  final totalRakaats = rakaats.isEmpty ? 2 : rakaats.length;
  final rakaatIndex = page.rakaatIndex.clamp(0, rakaats.length - 1);
  final orderIndexes = stepOrderIndexesForRakaatIndex(rakaatIndex);
  final stepIndex = page.stepIndex.clamp(0, orderIndexes.length - 1);
  final displayProgress = displayStepProgressFor(
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
  );
  final stepEntries = entriesForPage(rakaatIndex: rakaatIndex, stepIndex: stepIndex);
  final recitationEntries = recitationEntriesForPage(rakaatIndex: rakaatIndex, stepIndex: stepIndex);
  final step = stepEntries.firstOrNull;
  final title = (step?.title ?? '').trim().isEmpty
      ? context.t('stage.defaultStepTitle')
      : step!.title;
  final movementDescription = (step?.movementDescription ?? '').trim();
  final fallbackStepImageAsset = rakaats[rakaatIndex].imageAsset.isEmpty
      ? 'assets/icons/salat.png'
      : rakaats[rakaatIndex].imageAsset;
  final stepImageAsset = resolveStageStepImageAsset(
    explicitImageAsset: step?.imageAsset ?? '',
    stepCode: step?.stepCode ?? '',
    title: title,
    movementDescription: movementDescription,
    fallbackAsset: fallbackStepImageAsset,
    genderCode: GenderRepositoryMemory.instance.getSelectedGender().id,
  );

  final progressBlock = StageProgressBlock(
    title: context.t(
      'stage.prayerTitleWithRakaats',
      namedArgs: {'title': prayerTitle, 'count': '$totalRakaats'},
    ),
    rakaatIndex: rakaatIndex + 1,
    totalRakaats: totalRakaats,
    stepIndex: displayProgress.current,
    totalSteps: displayProgress.total,
    progress: displayProgress.total == 0
        ? 0
        : displayProgress.current / displayProgress.total,
    showRakaats: true,
    animateProgress: false,
  );

  final stepCard = StageStepCard(
    imageWidget: StageStepImage(
      stepImageAsset: stepImageAsset,
      fallbackStepImageAsset: fallbackStepImageAsset,
    ),
    title: title,
    description: movementDescription,
    textSize: cardTextSize,
  );

  final extraCards = [
    if (recitationEntries.isNotEmpty)
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < recitationEntries.length; i++) ...[
            StageAyahCard(
              ayahIndex: i,
              ayah: recitationEntries[i],
              textSize: cardTextSize,
              selected: false,
              isPlaying: false,
              progress: 0,
              onTap: () {},
              onPlayPause: () {},
            ),
            if (i != recitationEntries.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
  ];

  return StageOverviewPage(
    pageHeight: pageHeight,
    topInset: topInset,
    pageId: page.rakaatIndex * 1000 + page.stepIndex,
    progressBlock: progressBlock,
    stepCard: stepCard,
    extraCards: extraCards,
    scrollController: scrollController,
    shouldScheduleOverflowCheck: shouldScheduleOverflowCheck,
    setOverviewOverflow: setOverviewOverflow,
  );
}

extension _ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
