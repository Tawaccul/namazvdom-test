import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/text/transliteration_localizer.dart';
import '../../settings/language/data/language_repository_memory.dart';
import '../models/rakaat_models.dart';

class StageAdditionalSurahReplaceResult {
  const StageAdditionalSurahReplaceResult({
    required this.updatedRakaats,
    required this.targetStepIndex,
  });

  final List<RakaatData> updatedRakaats;
  final int targetStepIndex;
}

class StageAdditionalSurahHelper {
  static bool isAdditionalSurahStep(RakaatStep? step) {
    if (step == null) return false;
    return step.stepCode.trim().toLowerCase() == 'additional_surah' ||
        step.additionalSurahOptionCode.trim().isNotEmpty;
  }

  static int selectedIndexForStep({
    required List<RakaatSurahOption> options,
    required String? selectedAdditionalSurahCode,
    required RakaatStep? step,
  }) {
    if (options.isEmpty) return 0;
    final currentCode = step?.additionalSurahOptionCode.trim() ?? '';
    if (currentCode.isNotEmpty) {
      final fromCurrent = options.indexWhere(
        (item) => item.code == currentCode,
      );
      if (fromCurrent >= 0) return fromCurrent;
    }
    final selectedCode = selectedAdditionalSurahCode?.trim() ?? '';
    if (selectedCode.isNotEmpty) {
      final fromState = options.indexWhere((item) => item.code == selectedCode);
      if (fromState >= 0) return fromState;
    }
    final ikhlasIndex = options.indexWhere((item) => item.code == 'al_ikhlas');
    if (ikhlasIndex >= 0) return ikhlasIndex;
    return 0;
  }

  static Future<StageAdditionalSurahReplaceResult?>
  replaceAdditionalSurahSteps({
    required BuildContext context,
    required List<RakaatData> rakaats,
    required int rakaatIndex,
    required RakaatSurahOption option,
    required bool forceLocalOnly,
    required Map<String, bool> assetExistsMemo,
    required String Function(String? key, {String fallback}) translateKey,
    required Future<List<RakaatStep>> Function({
      required String surahCode,
      required String title,
      required int orderIndex,
      required String audioUrl,
    })
    loadRemoteSteps,
  }) async {
    if (rakaats.isEmpty) return null;
    final normalizedRakaatIndex = rakaatIndex.clamp(0, rakaats.length - 1);
    final rakaat = rakaats[normalizedRakaatIndex];
    final steps = [...rakaat.steps];
    final guideIndex = steps.indexWhere(
      (step) =>
          step.stepCode.trim().toLowerCase() == 'additional_surah' &&
          step.additionalSurahOptionCode.trim().isEmpty,
    );
    if (guideIndex < 0) return null;
    final guideOrderIndex = steps[guideIndex].orderIndex;

    steps.removeWhere(
      (step) =>
          step.stepCode.trim().toLowerCase() == 'additional_surah' &&
          step.additionalSurahOptionCode.trim().isNotEmpty,
    );

    final orderIndex = steps[guideIndex].orderIndex;
    final audioUrl = await _resolveAudioAssetPath(
      rakah: rakaat.number,
      stepCode: 'additional_surah',
      assetExistsMemo: assetExistsMemo,
    );

    final shouldPreferLocal = _shouldPreferLocalSurah(option.code);

    List<RakaatStep> inserted = const [];
    if (forceLocalOnly || shouldPreferLocal) {
      inserted = await _loadLocalAdditionalSurahSteps(
        surahCode: option.code,
        title: option.label,
        orderIndex: orderIndex,
        audioUrl: audioUrl,
        assetExistsMemo: assetExistsMemo,
        translateKey: translateKey,
      );
      if (inserted.isEmpty) return null;
    } else {
      try {
        inserted = await loadRemoteSteps(
          surahCode: option.code,
          title: option.label,
          orderIndex: orderIndex,
          audioUrl: audioUrl,
        );
        if (inserted.isEmpty) {
          inserted = await _loadLocalAdditionalSurahSteps(
            surahCode: option.code,
            title: option.label,
            orderIndex: orderIndex,
            audioUrl: audioUrl,
            assetExistsMemo: assetExistsMemo,
            translateKey: translateKey,
          );
        }
      } catch (_) {
        inserted = await _loadLocalAdditionalSurahSteps(
          surahCode: option.code,
          title: option.label,
          orderIndex: orderIndex,
          audioUrl: audioUrl,
          assetExistsMemo: assetExistsMemo,
          translateKey: translateKey,
        );
        if (inserted.isEmpty) rethrow;
      }
      if (inserted.isEmpty) return null;
    }

    steps.insertAll(guideIndex + 1, inserted);
    final updatedRakaats = [...rakaats];
    updatedRakaats[normalizedRakaatIndex] = RakaatData(
      number: rakaat.number,
      imageAsset: rakaat.imageAsset,
      steps: steps,
      additionalSurahOptions: rakaat.additionalSurahOptions,
    );

    final stepOrders = <int>{};
    for (final step in updatedRakaats[normalizedRakaatIndex].steps) {
      stepOrders.add(step.orderIndex);
    }
    final ordered = stepOrders.toList()..sort();
    final mappedIndex = ordered.indexOf(guideOrderIndex);
    if (mappedIndex < 0) return null;

    return StageAdditionalSurahReplaceResult(
      updatedRakaats: updatedRakaats,
      targetStepIndex: mappedIndex,
    );
  }

  static Future<String> _resolveAudioAssetPath({
    required int rakah,
    required String stepCode,
    required Map<String, bool> assetExistsMemo,
  }) async {
    final normalizedStepCode = stepCode.trim().toLowerCase();
    if (normalizedStepCode.isEmpty) return '';

    final byRakah = 'assets/audio/prayer/${rakah}_$normalizedStepCode.mp3';
    if (await _assetExists(byRakah, assetExistsMemo)) return byRakah;

    final byStepCode = 'assets/audio/prayer/$normalizedStepCode.mp3';
    if (await _assetExists(byStepCode, assetExistsMemo)) return byStepCode;

    final legacyByStepCode = 'assets/audio/$normalizedStepCode.mp3';
    if (await _assetExists(legacyByStepCode, assetExistsMemo)) {
      return legacyByStepCode;
    }

    return '';
  }

  static Future<bool> _assetExists(
    String path,
    Map<String, bool> assetExistsMemo,
  ) async {
    final memo = assetExistsMemo[path];
    if (memo != null) return memo;
    try {
      await rootBundle.load(path);
      assetExistsMemo[path] = true;
      return true;
    } catch (_) {
      assetExistsMemo[path] = false;
      return false;
    }
  }

  static bool _shouldPreferLocalSurah(String surahCode) {
    return switch (surahCode.trim().toLowerCase()) {
      'al_fatiha' || 'al_falaq' || 'an_nas' => true,
      _ => false,
    };
  }

  static Future<List<RakaatStep>> _loadLocalAdditionalSurahSteps({
    required String surahCode,
    required String title,
    required int orderIndex,
    required String audioUrl,
    required Map<String, bool> assetExistsMemo,
    required String Function(String? key, {String fallback}) translateKey,
  }) async {
    final normalized = surahCode.trim().toLowerCase();
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    if (normalized.isEmpty) return const [];
    final assetPath = 'assets/surahs/$normalized.json';
    if (!await _assetExists(assetPath, assetExistsMemo)) return const [];

    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw);
      if (json is! Map) return const [];
      final rows =
          (json.cast<String, dynamic>()['ayahs'] as List?)?.cast<dynamic>() ??
          const [];
      final ayahs = <RakaatStep>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = row.cast<String, dynamic>();
        final arabic =
            (map['arabic'] as String? ??
                    map['recitationArabic'] as String? ??
                    '')
                .trim();
        final transliteration = localizedTransliteration(
          (map['transliteration'] as String? ?? '').trim(),
          languageCode,
        );
        final translation = translateKey(
          map['translation_key'] as String?,
          fallback: (map['translation'] as String? ?? '').trim(),
        );
        if (arabic.isEmpty && transliteration.isEmpty && translation.isEmpty) {
          continue;
        }
        ayahs.add(
          RakaatStep(
            orderIndex: orderIndex,
            title: title,
            movementDescription: '',
            arabic: arabic,
            transliteration: transliteration,
            translation: translation,
            stepCode: 'additional_surah',
            audioUrl: audioUrl,
            surahCode: normalized,
            additionalSurahOptionCode: normalized,
          ),
        );
      }
      return ayahs.toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
