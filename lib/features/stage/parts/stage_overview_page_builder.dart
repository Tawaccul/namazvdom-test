import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../models/rakaat_models.dart';
import '../models/stage_step_screen_models.dart';
import 'stage_ayah_card.dart';
import 'stage_card.dart';
import 'stage_progress_bar.dart';
import 'stage_step_image.dart';

Widget buildStageOverviewPage({
  required BuildContext context,
  required List<RakaatData> rakaats,
  required StagePageReference page,
  required String prayerTitle,
  required double cardTextSize,
  required List<int> Function(int rakaatIndex) stepOrderIndexesForRakaatIndex,
  required DisplayedStepProgress Function({
    required int rakaatIndex,
    required int stepIndex,
  })
  displayStepProgressFor,
  required List<RakaatStep> Function({
    required int rakaatIndex,
    required int stepIndex,
  })
  entriesForPage,
  required List<RakaatStep> Function({
    required int rakaatIndex,
    required int stepIndex,
  })
  recitationEntriesForPage,
}) {
  final totalRakaats = rakaats.isEmpty ? 2 : rakaats.length;
  final rakaatIndex = page.rakaatIndex.clamp(0, rakaats.length - 1);
  final orderIndexes = stepOrderIndexesForRakaatIndex(rakaatIndex);
  final stepIndex = page.stepIndex.clamp(0, orderIndexes.length - 1);
  final displayProgress = displayStepProgressFor(
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
  );
  final stepEntries = entriesForPage(
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
  );
  final recitationEntries = recitationEntriesForPage(
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
  );
  final step = stepEntries.firstOrNull;
  final title = (step?.title ?? '').trim().isEmpty
      ? context.t('stage.defaultStepTitle')
      : step!.title;
  final movementDescription = (step?.movementDescription ?? '').trim();
  final fallbackStepImageAsset = rakaats[rakaatIndex].imageAsset.isEmpty
      ? 'assets/icons/salat.png'
      : rakaats[rakaatIndex].imageAsset;
  final selectedGenderCode = GenderRepositoryMemory.instance
      .getSelectedGender()
      .id;
  final stepImageAsset = resolveStageStepImageAsset(
    explicitImageAsset: step?.imageAsset ?? '',
    stepCode: step?.stepCode ?? '',
    title: title,
    movementDescription: movementDescription,
    fallbackAsset: fallbackStepImageAsset,
    genderCode: selectedGenderCode,
  );

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 21.h,
        bottom: 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StageProgressBlock(
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
            animateProgress: false,
          ),
          SizedBox(height: 12.h),
          StageCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 260.h,
                  decoration: BoxDecoration(
                    color: context.colors.soft,
                    borderRadius: BorderRadius.circular(AppRadii.inner.r),
                  ),
                  child: Center(
                    child: StageStepImage(
                      stepImageAsset: stepImageAsset,
                      fallbackStepImageAsset: fallbackStepImageAsset,
                    ),
                  ),
                ),
                SizedBox(height: 25.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: cardTextSize.sp,
                        height: 1.48,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (movementDescription.isNotEmpty)
                      Text(
                        movementDescription,
                        style: TextStyle(
                          fontSize: cardTextSize.sp,
                          height: 1.48,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (recitationEntries.isNotEmpty) ...[
            SizedBox(height: 12.h),
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
                  if (i != recitationEntries.length - 1) SizedBox(height: 16.h),
                ],
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

extension _ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
