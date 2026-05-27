import 'package:flutter/material.dart';

import '../../../app/app_dependencies_scope.dart';
import '../../../core/audio/audio_asset_resolver.dart';
import '../../../core/text/transliteration_localizer.dart';
import '../../prayer/domain/usecases/get_prayer_surah.dart';
import '../../settings/language/data/language_repository_memory.dart';
import '../models/rakaat_models.dart';
import '../parts/stage_additional_surah_helper.dart';
import '../stage_prayer_loader.dart';

class StageAdditionalSurahState {
  StageAdditionalSurahState({
    required void Function(VoidCallback) notify,
    required bool Function() isMounted,
    required BuildContext Function() getContext,
    required List<RakaatData> Function() getRakaats,
    required int Function() getRakaatIndex,
    required String Function(String? key, {String fallback}) translateKey,
    required void Function(List<RakaatData> updated) onRakaatsUpdated,
    required Future<void> Function(int stepIndex) onNavigateToStep,
    required void Function({bool disableAutoplay}) cancelAutoplay,
    required void Function(String? error) setError,
  })  : _notify = notify,
        _isMounted = isMounted,
        _getContext = getContext,
        _getRakaats = getRakaats,
        _getRakaatIndex = getRakaatIndex,
        _translateKey = translateKey,
        _onRakaatsUpdated = onRakaatsUpdated,
        _onNavigateToStep = onNavigateToStep,
        _cancelAutoplay = cancelAutoplay,
        _setError = setError;

  final void Function(VoidCallback) _notify;
  final bool Function() _isMounted;
  final BuildContext Function() _getContext;
  final List<RakaatData> Function() _getRakaats;
  final int Function() _getRakaatIndex;
  final String Function(String? key, {String fallback}) _translateKey;
  final void Function(List<RakaatData> updated) _onRakaatsUpdated;
  final Future<void> Function(int stepIndex) _onNavigateToStep;
  final void Function({bool disableAutoplay}) _cancelAutoplay;
  final void Function(String? error) _setError;

  String? selectedAdditionalSurahCode;
  int additionalSurahAnimationToken = 0;
  final Map<String, bool> assetExistsMemo = {};

  bool isAdditionalSurahStep(RakaatStep? step) =>
      StageAdditionalSurahHelper.isAdditionalSurahStep(step);

  int selectedIndexForStep(
    List<RakaatSurahOption> options,
    RakaatStep? step,
  ) => StageAdditionalSurahHelper.selectedIndexForStep(
    options: options,
    selectedAdditionalSurahCode: selectedAdditionalSurahCode,
    step: step,
  );

  Future<void> onSelectAdditionalSurah({
    required List<RakaatSurahOption> options,
    required int optionIndex,
  }) async {
    if (optionIndex < 0 || optionIndex >= options.length) return;
    final option = options[optionIndex];
    _notify(() => selectedAdditionalSurahCode = option.code);
    try {
      final result =
          await StageAdditionalSurahHelper.replaceAdditionalSurahSteps(
            context: _getContext(),
            rakaats: _getRakaats(),
            rakaatIndex: _getRakaatIndex(),
            option: option,
            forceLocalOnly: StagePrayerLoader.forceLocalOnly,
            assetExistsMemo: assetExistsMemo,
            translateKey: _translateKey,
            loadRemoteSteps: _loadRemoteSteps,
          );
      if (result == null || !_isMounted()) return;
      _onRakaatsUpdated(result.updatedRakaats);
      _notify(() => additionalSurahAnimationToken++);
      _cancelAutoplay(disableAutoplay: true);
      await _onNavigateToStep(result.targetStepIndex);
    } catch (e) {
      if (!_isMounted()) return;
      _setError(e.toString());
    }
  }

  Future<List<RakaatStep>> _loadRemoteSteps({
    required String surahCode,
    required String title,
    required int orderIndex,
    required String audioUrl,
  }) async {
    final context = _getContext();
    final repository = AppDependenciesScope.prayerRepositoryOf(context);
    final getPrayerSurah = GetPrayerSurah(repository);
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    final surah = await getPrayerSurah(
      surahCode: surahCode,
      languageCode: languageCode,
    );
    final mapped = <RakaatStep>[];
    for (var i = 0; i < surah.ayahs.length; i++) {
      final ayah = surah.ayahs[i];
      final perAyahAudio = AudioAssetResolver.forSurahAyah(surahCode, i);
      mapped.add(
        RakaatStep(
          orderIndex: orderIndex,
          title: title,
          movementDescription: '',
          arabic: ayah.recitationArabic,
          transliteration: localizedTransliteration(
            ayah.transliteration,
            languageCode,
          ),
          translation: ayah.translation,
          stepCode: 'additional_surah',
          audioUrl: perAyahAudio.isNotEmpty ? perAyahAudio : audioUrl,
          surahCode: surahCode,
          additionalSurahOptionCode: surahCode,
        ),
      );
    }
    return mapped;
  }
}
