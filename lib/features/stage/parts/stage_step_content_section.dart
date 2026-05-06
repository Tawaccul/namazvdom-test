import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_radii.dart';
import '../models/rakaat_models.dart';
import 'stage_ayah_card.dart';
import 'stage_bottom_button.dart';
import 'stage_card.dart';
import 'stage_surah_selector.dart';

class StageStepContentSection extends StatelessWidget {
  const StageStepContentSection({
    super.key,
    required this.animateStepTransition,
    required this.animateRakaat,
    required this.animateAppear,
    required this.stepTitle,
    required this.movementDescription,
    required this.cardTextSize,
    required this.softColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.stepImage,
    required this.hasAdditionalSurahSelector,
    required this.additionalSurahOptions,
    required this.selectedAdditionalSurahIndex,
    required this.onSelectAdditionalSurah,
    required this.currentStepEntries,
    required this.additionalSurahAnimationToken,
    required this.entryKeyFor,
    required this.keyForEntry,
    required this.playingStepKey,
    required this.isAudioPlaying,
    required this.audioProgress,
    required this.onAyahTap,
    required this.errorText,
    required this.navButtonsVisible,
    required this.hasPrevStageStep,
    required this.hasNextStageStep,
    required this.canGoBack,
    required this.canGoNext,
    required this.backButtonLabel,
    required this.nextButtonLabel,
    required this.onPrevStep,
    required this.onNextStep,
    this.navButtonsOpacity = 1.0,
    this.isGhost = false,
  });

  final Widget Function(Widget child) animateStepTransition;
  final Widget Function(Widget child) animateRakaat;
  final Widget Function(Widget child) animateAppear;
  final String stepTitle;
  final String movementDescription;
  final double cardTextSize;
  final Color softColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Widget stepImage;
  final bool hasAdditionalSurahSelector;
  final List<RakaatSurahOption> additionalSurahOptions;
  final int selectedAdditionalSurahIndex;
  final ValueChanged<int> onSelectAdditionalSurah;
  final List<RakaatStep> currentStepEntries;
  final int additionalSurahAnimationToken;
  final String Function(int index) entryKeyFor;
  final Key Function(int index) keyForEntry;
  final String? playingStepKey;
  final bool isAudioPlaying;
  final double audioProgress;
  final ValueChanged<int> onAyahTap;
  final String? errorText;
  final bool navButtonsVisible;
  final bool hasPrevStageStep;
  final bool hasNextStageStep;
  final bool canGoBack;
  final bool canGoNext;
  final String backButtonLabel;
  final String nextButtonLabel;
  final VoidCallback? onPrevStep;
  final VoidCallback? onNextStep;
  final double navButtonsOpacity;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    final recitationCards = Column(
      children: [
        for (var i = 0; i < currentStepEntries.length; i++) ...[
          () {
            final entry = currentStepEntries[i];
            final entryKey = entryKeyFor(i);
            final isSelected = playingStepKey == entryKey;
            final isEntryPlaying = isSelected && isAudioPlaying;
            return KeyedSubtree(
              key: isGhost
                  ? ValueKey('ghost-ayah-$i')
                  : hasAdditionalSurahSelector
                      ? ValueKey('additional-surah-$i-${entry.surahCode}')
                      : keyForEntry(i),
              child: StageAyahCard(
                ayahIndex: i,
                ayah: entry,
                textSize: cardTextSize,
                selected: isSelected,
                isPlaying: isEntryPlaying,
                progress: isSelected ? audioProgress.clamp(0.0, 1.0) : 0.0,
                onTap: () => onAyahTap(i),
                onPlayPause: () => onAyahTap(i),
              ),
            );
          }(),
          if (i != currentStepEntries.length - 1) SizedBox(height: 16),
        ],
      ],
    );
    final recitationContent = hasAdditionalSurahSelector
        ? TweenAnimationBuilder<double>(
            key: ValueKey<int>(additionalSurahAnimationToken),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final scale = 0.985 + (0.015 * value);
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: recitationCards,
          )
        : recitationCards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        animateStepTransition(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              animateRakaat(
                animateAppear(
                  StageCard(
                    child: Column(
                      children: [
                        Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: softColor,
                            borderRadius: BorderRadius.circular(
                              AppRadii.inner,
                            ),
                          ),
                          child: Center(child: stepImage),
                        ),
                        SizedBox(height: 25),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              stepTitle,
                              style: TextStyle(
                                fontSize: cardTextSize.sp,
                                height: 1.48,
                                fontWeight: FontWeight.w500,
                                color: textPrimaryColor,
                              ),
                            ),
                            SizedBox(height: 10),
                            if (movementDescription.isNotEmpty)
                              Text(
                                movementDescription,
                                style: TextStyle(
                                  fontSize: cardTextSize.sp,
                                  height: 1.48,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              if (hasAdditionalSurahSelector) ...[
                animateAppear(
                  StageSurahSelector(
                    labels: additionalSurahOptions
                        .map((option) => option.label)
                        .toList(growable: false),
                    selectedIndex: selectedAdditionalSurahIndex,
                    onSelect: onSelectAdditionalSurah,
                  ),
                ),
                SizedBox(height: 12),
              ],
              animateRakaat(animateAppear(recitationContent)),
              if (errorText != null) ...[
                SizedBox(height: 12),
                StageCard(
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (navButtonsVisible) ...[
          SizedBox(height: 20),
          IgnorePointer(
            ignoring: navButtonsOpacity < 0.5,
            child: Opacity(
              opacity: navButtonsOpacity.clamp(0.0, 1.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      opacity: hasPrevStageStep ? 1 : 0.5,
                      child: StageBottomButton(
                        variant: StageBottomButtonVariant.secondary,
                        label: backButtonLabel,
                        icon: 'assets/icons/arrow-left.svg',
                        onTap: canGoBack ? onPrevStep : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      opacity: hasNextStageStep ? 1 : 0.5,
                      child: StageBottomButton(
                        variant: StageBottomButtonVariant.primary,
                        label: nextButtonLabel,
                        icon: 'assets/icons/arrow-right.svg',
                        onTap: canGoNext ? onNextStep : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
