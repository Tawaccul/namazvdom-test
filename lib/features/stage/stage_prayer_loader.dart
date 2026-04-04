import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../app/app_dependencies_scope.dart';
import '../prayer/domain/entities/prayer_rakaat.dart';
import '../prayer/domain/entities/prayer_request_context.dart';
import '../prayer/domain/entities/prayer_step.dart';
import '../prayer/domain/usecases/get_prayer_rakaats.dart';
import '../prayer/domain/usecases/get_prayer_surah.dart';
import '../settings/gender/data/gender_repository_memory.dart';
import '../settings/language/data/language_repository_memory.dart';
import '../settings/madhhab/data/madhhab_repository_memory.dart';
import 'models/rakaat_models.dart';

class StagePrayerLoader {
  const StagePrayerLoader._();

  static bool forceLocalOnly = true;

  static Future<List<RakaatData>> load(
    BuildContext context, {
    required String prayerCode,
  }) async {
    final repository = AppDependenciesScope.prayerRepositoryOf(context);
    final getPrayerRakaats = GetPrayerRakaats(repository);
    final getPrayerSurah = GetPrayerSurah(repository);
    final translationMap = await _loadTranslationsForLanguage(
      LanguageRepositoryMemory.instance.getSelectedLanguage().id,
    );
    final normalizedPrayerCode = _normalizePrayerCode(prayerCode);
    if (forceLocalOnly) {
      final localOnlyData = await _tryLoadPrayerFromLocalAssets(
        prayerCode: normalizedPrayerCode,
        translations: translationMap,
      );
      if (localOnlyData != null && localOnlyData.isNotEmpty) {
        return localOnlyData;
      }
      throw StateError('prayer_not_found');
    }

    if (normalizedPrayerCode == 'fajr') {
      final fixedLocal = await _tryLoadPrayerFromLocalAssets(
        prayerCode: normalizedPrayerCode,
        translations: translationMap,
      );
      if (fixedLocal != null && fixedLocal.isNotEmpty) return fixedLocal;
    }
    final fallbackChain = _buildContextFallbackChain(
      prayerCode: normalizedPrayerCode,
    );

    Object? lastError;
    for (var index = 0; index < fallbackChain.length; index++) {
      final requestContext = fallbackChain[index];
      try {
        final rakaats = await getPrayerRakaats(baseContext: requestContext);
        return _mapPrayerToStageRakaats(
          rakaats,
          prayerCode: normalizedPrayerCode,
          getPrayerSurah: getPrayerSurah,
          languageCode: _resolveLanguageCode(rakaats, requestContext),
        );
      } catch (error) {
        if (_isPrayerNotFoundError(error)) {
          final localFallback = await _tryLoadPrayerFromLocalAssets(
            prayerCode: normalizedPrayerCode,
            translations: translationMap,
          );
          if (localFallback != null) return localFallback;
          throw StateError('prayer_not_found');
        }
        lastError = error;
        final hasNext = index < fallbackChain.length - 1;
        final canRetryWithNextLanguage =
            hasNext && _isLanguageNotFoundError(error.toString());
        if (canRetryWithNextLanguage) continue;
        break;
      }
    }

    final localFallback = await _tryLoadPrayerFromLocalAssets(
      prayerCode: normalizedPrayerCode,
      translations: translationMap,
    );
    if (localFallback != null) return localFallback;

    throw lastError ?? StateError('prayer_load_failed');
  }
}

String _normalizePrayerCode(String prayerCode) {
  final normalized = prayerCode.trim().toLowerCase();
  return switch (normalized) {
    'zuhr' => 'dhuhr',
    'magrib' => 'maghrib',
    _ => normalized,
  };
}

PrayerRequestContext _contextForLanguage({
  required String prayerCode,
  required String languageCode,
}) {
  final script = switch (languageCode) {
    'ru' => 'cyrillic',
    _ => 'latin',
  };
  final genderCode = GenderRepositoryMemory.instance.getSelectedGender().id;
  final madhhabCode = MadhhabRepositoryMemory.instance.getSelectedMadhhab().id;
  return PrayerRequestContext(
    prayerCode: prayerCode,
    madhhabCode: madhhabCode,
    genderCode: genderCode,
    languageCode: languageCode,
    rakah: 1,
    script: script,
  );
}

List<PrayerRequestContext> _buildContextFallbackChain({
  required String prayerCode,
}) {
  final selectedLanguageCode = LanguageRepositoryMemory.instance
      .getSelectedLanguage()
      .id;
  final languageCandidates = <String>[
    selectedLanguageCode,
    if (selectedLanguageCode != 'ru') 'ru',
    if (selectedLanguageCode != 'en') 'en',
  ];
  return languageCandidates
      .map(
        (languageCode) => _contextForLanguage(
          prayerCode: prayerCode,
          languageCode: languageCode,
        ),
      )
      .toList(growable: false);
}

bool _isLanguageNotFoundError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('language not found');
}

bool _isPrayerNotFoundError(Object error) {
  if (error is DioException) {
    return error.response?.statusCode == 404;
  }
  final lower = error.toString().toLowerCase();
  return lower.contains('404') &&
      (lower.contains('prayer') || lower.contains('not found'));
}

String _resolveLanguageCode(
  List<PrayerRakaat> rakaats,
  PrayerRequestContext fallback,
) {
  final fromData = rakaats.firstOrNull?.context.languageCode.trim() ?? '';
  if (fromData.isNotEmpty) return fromData;
  final fromContext = fallback.languageCode?.trim() ?? '';
  if (fromContext.isNotEmpty) return fromContext;
  return 'ru';
}

Future<List<RakaatData>> _mapPrayerToStageRakaats(
  List<PrayerRakaat> rakaats, {
  required String prayerCode,
  required GetPrayerSurah getPrayerSurah,
  required String languageCode,
}) async {
  final mapped = <RakaatData>[];
  for (final rakaat in rakaats) {
    final orderedSteps = [...rakaat.steps]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final stageSteps = <RakaatStep>[];
    final additionalSurahOptions = <RakaatSurahOption>[];

    for (final step in orderedSteps) {
      final stepAudioPath = await _resolveAudioAssetPath(
        rakah: rakaat.context.rakah,
        stepCode: step.stepCode,
      );
      if (_isAdditionalSurahStep(step)) {
        stageSteps.add(
          RakaatStep(
            orderIndex: step.orderIndex,
            title: _stageStepTitle(step.stepCode),
            movementDescription: step.content.movementDescription,
            arabic: step.content.recitationArabic,
            transliteration: step.content.transliteration,
            translation: step.content.translation,
            stepCode: step.stepCode,
            audioUrl: stepAudioPath,
          ),
        );
        final normalized = _normalizeSurahOptions(step.availableSurahs);
        additionalSurahOptions.addAll(
          normalized.map(
            (option) =>
                RakaatSurahOption(code: option.code, label: option.name),
          ),
        );
        continue;
      }

      final surahCode = (step.surahCode ?? '').trim();
      if (surahCode.isNotEmpty) {
        stageSteps.addAll(
          await _mapSurahToStageSteps(
            getPrayerSurah: getPrayerSurah,
            languageCode: languageCode,
            surahCode: surahCode,
            title: _stageStepTitle(step.stepCode),
            stepCode: step.stepCode,
            stepOrderIndex: step.orderIndex,
            audioUrl: stepAudioPath,
          ),
        );
        continue;
      }

      stageSteps.add(
        RakaatStep(
          orderIndex: step.orderIndex,
          title: _stageStepTitle(step.stepCode),
          movementDescription: step.content.movementDescription,
          arabic: step.content.recitationArabic,
          transliteration: step.content.transliteration,
          translation: step.content.translation,
          stepCode: step.stepCode,
          audioUrl: stepAudioPath,
        ),
      );
    }

    mapped.add(
      RakaatData(
        number: rakaat.context.rakah,
        imageAsset: rakaat.context.rakah == 1
            ? 'assets/icons/salat-1.png'
            : 'assets/icons/salat.png',
        steps: stageSteps,
        additionalSurahOptions: additionalSurahOptions,
      ),
    );
  }
  return _normalizeFajrStepCounts(mapped, prayerCode: prayerCode);
}

List<RakaatData> _normalizeFajrStepCounts(
  List<RakaatData> input, {
  required String prayerCode,
}) {
  if (prayerCode.trim().toLowerCase() != 'fajr') return input;
  if (input.isEmpty) return input;
  const targetsByRakaatNumber = <int, int>{1: 16, 2: 18};

  return input
      .map((rakaat) {
        final target = targetsByRakaatNumber[rakaat.number];
        if (target == null || target <= 0) return rakaat;
        final normalized = _rebalanceRakaatOrderIndexes(
          rakaat.steps,
          targetUniqueStepCount: target,
        );
        return RakaatData(
          number: rakaat.number,
          imageAsset: rakaat.imageAsset,
          steps: normalized,
          additionalSurahOptions: rakaat.additionalSurahOptions,
        );
      })
      .toList(growable: false);
}

List<RakaatStep> _rebalanceRakaatOrderIndexes(
  List<RakaatStep> steps, {
  required int targetUniqueStepCount,
}) {
  if (steps.isEmpty) return steps;
  final currentUniqueSet = steps.map((step) => step.orderIndex).toSet();
  final currentUnique = currentUniqueSet.length;
  if (currentUnique == targetUniqueStepCount) return steps;

  if (currentUnique > targetUniqueStepCount) {
    final orderedUnique = currentUniqueSet.toList()..sort();
    final remap = <int, int>{};
    for (var i = 0; i < orderedUnique.length; i++) {
      remap[orderedUnique[i]] = i < targetUniqueStepCount
          ? i + 1
          : targetUniqueStepCount;
    }
    return steps
        .map(
          (step) => _copyStepWithOrderIndex(
            step,
            remap[step.orderIndex] ?? targetUniqueStepCount,
          ),
        )
        .toList(growable: false);
  }

  var remainingExtra = targetUniqueStepCount - currentUnique;
  if (remainingExtra <= 0) return steps;

  final groupedByOriginalOrder = <int, List<RakaatStep>>{};
  final orderedIndexes = <int>[];
  for (final step in steps) {
    final bucket = groupedByOriginalOrder.putIfAbsent(step.orderIndex, () {
      orderedIndexes.add(step.orderIndex);
      return <RakaatStep>[];
    });
    bucket.add(step);
  }

  var nextOrderIndex = 1;
  final result = <RakaatStep>[];
  for (final originalOrder in orderedIndexes) {
    final group = groupedByOriginalOrder[originalOrder] ?? const <RakaatStep>[];
    if (group.isEmpty) continue;
    final maxSplitInGroup = group.length - 1;
    final splitInGroup = remainingExtra <= 0
        ? 0
        : (remainingExtra < maxSplitInGroup ? remainingExtra : maxSplitInGroup);

    for (var itemIndex = 0; itemIndex < group.length; itemIndex++) {
      final step = group[itemIndex];
      final offset = itemIndex <= splitInGroup ? itemIndex : splitInGroup;
      final reassignedOrder = nextOrderIndex + offset;
      result.add(_copyStepWithOrderIndex(step, reassignedOrder));
    }

    nextOrderIndex += 1 + splitInGroup;
    remainingExtra -= splitInGroup;
  }

  if (remainingExtra > 0 && result.isNotEmpty) {
    final filler = result.last;
    while (remainingExtra > 0) {
      result.add(_copyStepWithOrderIndex(filler, nextOrderIndex));
      nextOrderIndex += 1;
      remainingExtra -= 1;
    }
  }

  return result.toList(growable: false);
}

RakaatStep _copyStepWithOrderIndex(RakaatStep step, int orderIndex) {
  return RakaatStep(
    orderIndex: orderIndex,
    title: step.title,
    movementDescription: step.movementDescription,
    arabic: step.arabic,
    transliteration: step.transliteration,
    translation: step.translation,
    stepCode: step.stepCode,
    audioUrl: step.audioUrl,
    surahCode: step.surahCode,
    additionalSurahOptionCode: step.additionalSurahOptionCode,
  );
}

bool _isAdditionalSurahStep(PrayerStep step) {
  return step.stepCode.trim().toLowerCase() == 'additional_surah';
}

List<PrayerStepSurahOption> _normalizeSurahOptions(
  List<PrayerStepSurahOption> items,
) {
  final deduped = <String, PrayerStepSurahOption>{};
  for (final item in items) {
    final code = item.code.trim();
    if (code.isEmpty) continue;
    final fallbackLabel = _stageStepTitle(code);
    final name = item.name.trim().isEmpty ? fallbackLabel : item.name.trim();
    deduped[code] = PrayerStepSurahOption(code: code, name: name);
  }
  return deduped.values.toList(growable: false);
}

Future<List<RakaatStep>> _mapSurahToStageSteps({
  required GetPrayerSurah getPrayerSurah,
  required String languageCode,
  required String surahCode,
  required String title,
  required String stepCode,
  required int stepOrderIndex,
  required String audioUrl,
  String additionalSurahOptionCode = '',
}) async {
  final surah = await getPrayerSurah(
    surahCode: surahCode,
    languageCode: languageCode,
  );
  final displayTitle = title.trim().isEmpty
      ? _stageStepTitle(surahCode)
      : title;
  return surah.ayahs
      .map(
        (ayah) => RakaatStep(
          orderIndex: stepOrderIndex,
          title: displayTitle,
          movementDescription: '',
          arabic: ayah.recitationArabic,
          transliteration: ayah.transliteration,
          translation: ayah.translation,
          stepCode: stepCode,
          audioUrl: audioUrl,
          surahCode: surahCode,
          additionalSurahOptionCode: additionalSurahOptionCode,
        ),
      )
      .toList(growable: false);
}

String _stageStepTitle(String code) {
  final normalized = code.trim();
  if (normalized.isEmpty) return _localizeStageText(en: 'Step', ru: 'Шаг');
  if (normalized.toLowerCase() == 'additional_surah') {
    return _localizeStageText(
      en: 'Reading additional Surahs',
      ru: 'Чтение дополнительных сур',
    );
  }
  final parts = normalized
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty);
  return parts
      .map(
        (part) => part.length <= 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _localizeStageText({required String en, required String ru}) {
  final selectedLanguageCode = LanguageRepositoryMemory.instance
      .getSelectedLanguage()
      .id;
  return selectedLanguageCode == 'ru' ? ru : en;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final Map<String, bool> _assetExistsMemo = {};

Future<bool> _assetExists(String path) async {
  final memo = _assetExistsMemo[path];
  if (memo != null) return memo;
  try {
    await rootBundle.load(path);
    _assetExistsMemo[path] = true;
    return true;
  } catch (_) {
    _assetExistsMemo[path] = false;
    return false;
  }
}

Future<String> _resolveAudioAssetPath({
  required int rakah,
  required String stepCode,
}) async {
  final normalizedStepCode = stepCode.trim().toLowerCase();
  if (normalizedStepCode.isEmpty) return '';

  final byRakah = 'assets/audio/prayer/${rakah}_$normalizedStepCode.mp3';
  if (await _assetExists(byRakah)) return byRakah;

  final byStepCode = 'assets/audio/prayer/$normalizedStepCode.mp3';
  if (await _assetExists(byStepCode)) return byStepCode;

  final legacyByStepCode = 'assets/audio/$normalizedStepCode.mp3';
  if (await _assetExists(legacyByStepCode)) return legacyByStepCode;

  return '';
}

Future<List<RakaatData>?> _tryLoadPrayerFromLocalAssets({
  required String prayerCode,
  required Map<String, dynamic> translations,
}) async {
  final normalizedPrayerCode = _normalizePrayerCode(prayerCode);
  if (normalizedPrayerCode.isEmpty) return null;
  final manifestAssetPath =
      'assets/$normalizedPrayerCode/$normalizedPrayerCode.json';
  if (!await _assetExists(manifestAssetPath)) return null;

  try {
    final raw = await rootBundle.loadString(manifestAssetPath);
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    final map = json.cast<String, dynamic>();
    final rawRakaats = (map['rakaats'] as List?)?.cast<dynamic>() ?? const [];
    final rakaats = <RakaatData>[];

    for (final rawRakaat in rawRakaats) {
      if (rawRakaat is! Map) continue;
      final rakaatMap = rawRakaat.cast<String, dynamic>();
      final rakaatNumber =
          (rakaatMap['id'] as num?)?.toInt() ?? (rakaats.length + 1);
      final rawSteps =
          (rakaatMap['steps'] as List?)?.cast<dynamic>() ?? const [];

      final mapped = await _mapLocalStepsToRakaatData(
        prayerCode: normalizedPrayerCode,
        rakaatNumber: rakaatNumber,
        rawSteps: rawSteps,
        translations: translations,
      );
      rakaats.add(
        RakaatData(
          number: rakaatNumber,
          imageAsset: rakaatNumber == 1
              ? 'assets/icons/salat-1.png'
              : 'assets/icons/salat.png',
          steps: mapped.steps,
          additionalSurahOptions: mapped.additionalSurahOptions,
        ),
      );
    }

    if (rakaats.isEmpty) return null;
    return _normalizeFajrStepCounts(rakaats, prayerCode: normalizedPrayerCode);
  } catch (_) {
    return null;
  }
}

Future<_LocalRakaatMappedData> _mapLocalStepsToRakaatData({
  required String prayerCode,
  required int rakaatNumber,
  required List<dynamic> rawSteps,
  required Map<String, dynamic> translations,
}) async {
  final steps = <RakaatStep>[];
  final additionalSurahOptions = <RakaatSurahOption>[];

  for (var index = 0; index < rawSteps.length; index++) {
    final rawStep = rawSteps[index];
    if (rawStep is! Map) continue;
    final stepMap = rawStep.cast<String, dynamic>();
    final orderIndex = (stepMap['id'] as num?)?.toInt() ?? (index + 1);
    final type = (stepMap['type'] as String? ?? '').trim().toLowerCase();
    final imagePath = (stepMap['image'] as String? ?? '').trim();
    final explicitTitleKey = (stepMap['title_key'] as String? ?? '').trim();
    final explicitDescriptionKey = (stepMap['description_key'] as String? ?? '')
        .trim();
    final fallbackTitleKey = '$prayerCode.r$rakaatNumber.s$orderIndex.title';
    final fallbackDescriptionKey =
        '$prayerCode.r$rakaatNumber.s$orderIndex.description';
    final title =
        _lookupTranslationValue(
          translations,
          explicitTitleKey.isEmpty ? fallbackTitleKey : explicitTitleKey,
        ) ??
        _lookupTranslationValue(translations, fallbackTitleKey) ??
        (stepMap['title'] as String? ?? '').trim();
    final movementDescription =
        _lookupTranslationValue(
          translations,
          explicitDescriptionKey.isEmpty
              ? fallbackDescriptionKey
              : explicitDescriptionKey,
        ) ??
        _lookupTranslationValue(translations, fallbackDescriptionKey) ??
        (stepMap['description'] as String? ?? '').trim();
    final stepCode = _stepCodeFromLocalImage(
      imagePath: imagePath,
      fallback: type == 'surah_choice' ? 'additional_surah' : 'step',
    );
    final audioPath = await _resolveAudioAssetPath(
      rakah: rakaatNumber,
      stepCode: stepCode,
    );

    if (type == 'surah') {
      final surahCode = (stepMap['surah_id'] as String? ?? '')
          .trim()
          .toLowerCase();
      final ayahs = await _loadLocalSurahAyahs(
        surahCode: surahCode,
        translations: translations,
      );
      if (ayahs.isEmpty) {
        steps.add(
          RakaatStep(
            orderIndex: orderIndex,
            title: title,
            movementDescription: movementDescription,
            arabic: '',
            transliteration: '',
            translation: '',
            stepCode: stepCode,
            audioUrl: audioPath,
            surahCode: surahCode,
          ),
        );
        continue;
      }
      steps.addAll(
        ayahs.map(
          (ayah) => RakaatStep(
            orderIndex: orderIndex,
            title: title,
            movementDescription: movementDescription,
            arabic: ayah.recitationArabic,
            transliteration: ayah.transliteration,
            translation: ayah.translation,
            stepCode: stepCode,
            audioUrl: audioPath,
            surahCode: surahCode,
          ),
        ),
      );
      continue;
    }

    if (type == 'surah_choice') {
      final options =
          (stepMap['options'] as List?)?.cast<dynamic>() ?? const <dynamic>[];
      final normalized = await _normalizeLocalSurahOptions(
        options,
        translations: translations,
      );
      additionalSurahOptions.addAll(normalized);
      steps.add(
        RakaatStep(
          orderIndex: orderIndex,
          title: title,
          movementDescription: movementDescription,
          arabic: '',
          transliteration: '',
          translation: '',
          stepCode: 'additional_surah',
          audioUrl: audioPath,
        ),
      );
      if (normalized.isNotEmpty) {
        final selected = normalized.firstWhere(
          (item) => item.code == 'al_ikhlas',
          orElse: () => normalized.first,
        );
        final ayahs = await _loadLocalSurahAyahs(
          surahCode: selected.code,
          translations: translations,
        );
        steps.addAll(
          ayahs.map(
            (ayah) => RakaatStep(
              orderIndex: orderIndex,
              title: selected.label,
              movementDescription: '',
              arabic: ayah.recitationArabic,
              transliteration: ayah.transliteration,
              translation: ayah.translation,
              stepCode: 'additional_surah',
              audioUrl: audioPath,
              surahCode: selected.code,
              additionalSurahOptionCode: selected.code,
            ),
          ),
        );
      }
      continue;
    }

    final textMap = (stepMap['text'] as Map?)?.cast<String, dynamic>();
    final textArabic = (textMap?['arabic'] as String? ?? '').trim();
    final textTransliteration = (textMap?['transliteration'] as String? ?? '')
        .trim();
    final explicitTextTranslationKey =
        (textMap?['translation_key'] as String? ?? '').trim();
    final fallbackTextTranslationKey =
        '$prayerCode.r$rakaatNumber.s$orderIndex.text';
    final textTranslation =
        _lookupTranslationValue(
          translations,
          explicitTextTranslationKey.isEmpty
              ? fallbackTextTranslationKey
              : explicitTextTranslationKey,
        ) ??
        _lookupTranslationValue(translations, fallbackTextTranslationKey) ??
        (textMap?['translation'] as String? ?? '').trim();
    steps.add(
      RakaatStep(
        orderIndex: orderIndex,
        title: title,
        movementDescription: movementDescription,
        arabic: textArabic,
        transliteration: textTransliteration,
        translation: textTranslation,
        stepCode: stepCode,
        audioUrl: audioPath,
      ),
    );
  }

  return _LocalRakaatMappedData(
    steps: steps.toList(growable: false),
    additionalSurahOptions: additionalSurahOptions.toList(growable: false),
  );
}

Future<List<RakaatSurahOption>> _normalizeLocalSurahOptions(
  List<dynamic> rawOptions, {
  required Map<String, dynamic> translations,
}) async {
  final deduped = <String, RakaatSurahOption>{};
  for (final option in rawOptions) {
    final code = (option as String? ?? '').trim().toLowerCase();
    if (code.isEmpty) continue;
    final surahAssetPath = 'assets/surahs/$code.json';
    if (!await _assetExists(surahAssetPath)) continue;
    final label =
        _lookupTranslationValue(translations, 'surah.names.$code') ??
        _prettySurahCodeLabel(code);
    deduped[code] = RakaatSurahOption(code: code, label: label);
  }
  return deduped.values.toList(growable: false);
}

Future<List<_LocalSurahAyah>> _loadLocalSurahAyahs({
  required String surahCode,
  required Map<String, dynamic> translations,
}) async {
  if (surahCode.isEmpty) return const [];
  final assetPath = 'assets/surahs/$surahCode.json';
  if (!await _assetExists(assetPath)) return const [];

  try {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw);
    if (json is! Map) return const [];
    final map = json.cast<String, dynamic>();
    final rows = (map['ayahs'] as List?)?.cast<dynamic>() ?? const [];

    final deduped = <String, _LocalSurahAyah>{};
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is! Map) continue;
      final ayah = row.cast<String, dynamic>();
      final arabic =
          (ayah['arabic'] as String? ??
                  ayah['recitationArabic'] as String? ??
                  '')
              .trim();
      final transliteration = (ayah['transliteration'] as String? ?? '').trim();
      final translation = _translateKey(
        translations,
        ayah['translation_key'] as String?,
        fallback: (ayah['translation'] as String? ?? '').trim(),
      );
      if (arabic.isEmpty && transliteration.isEmpty && translation.isEmpty) {
        continue;
      }
      final fingerprint = '$arabic|$transliteration|$translation';
      deduped[fingerprint] = _LocalSurahAyah(
        recitationArabic: arabic,
        translation: translation,
        transliteration: transliteration,
      );
    }
    return deduped.values.toList(growable: false);
  } catch (_) {
    return const [];
  }
}

String _translateKey(
  Map<String, dynamic> translations,
  String? key, {
  String fallback = '',
}) {
  final normalized = (key ?? '').trim();
  if (normalized.isEmpty) return fallback;
  final resolved = _readNestedTranslationValue(translations, normalized);
  if (resolved is String && resolved.trim().isNotEmpty) return resolved.trim();
  return fallback.isEmpty ? normalized : fallback;
}

String? _lookupTranslationValue(Map<String, dynamic> root, String? keyPath) {
  final normalized = (keyPath ?? '').trim();
  if (normalized.isEmpty) return null;
  final value = _readNestedTranslationValue(root, normalized);
  if (value is! String) return null;
  final result = value.trim();
  if (result.isEmpty) return null;
  return result;
}

Object? _readNestedTranslationValue(Map<String, dynamic> root, String keyPath) {
  final parts = keyPath.split('.').where((part) => part.isNotEmpty);
  Object? cursor = root;
  for (final part in parts) {
    if (cursor is! Map) return null;
    cursor = cursor[part];
  }
  return cursor;
}

Future<Map<String, dynamic>> _loadTranslationsForLanguage(
  String languageCode,
) async {
  final normalized = languageCode.trim().toLowerCase();
  final candidates = <String>[
    if (normalized.isNotEmpty) normalized,
    if (normalized != 'ru') 'ru',
    if (normalized != 'en') 'en',
  ];
  for (final code in candidates) {
    final path = 'assets/translations/$code.json';
    if (!await _assetExists(path)) continue;
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return json;
      if (json is Map) return json.cast<String, dynamic>();
    } catch (_) {
      continue;
    }
  }
  return const <String, dynamic>{};
}

String _prettySurahCodeLabel(String code) {
  final parts = code.split('_').where((part) => part.isNotEmpty);
  return parts
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join('-');
}

String _stepCodeFromLocalImage({
  required String imagePath,
  required String fallback,
}) {
  final normalized = imagePath.trim().toLowerCase();
  if (normalized.contains('takbir')) return 'takbir';
  if (normalized.contains('ruku')) return 'ruku';
  if (normalized.contains('sudjud') || normalized.contains('sujud')) {
    return 'sujud';
  }
  if (normalized.contains('taslim-left')) return 'taslim_left';
  if (normalized.contains('taslim-right')) return 'taslim_right';
  if (normalized.contains('at-tahiyat')) return 'at_tahiyat';
  if (normalized.contains('seat')) return 'jalsa';
  if (normalized.contains('stay')) return 'qiyam';
  return fallback;
}

class _LocalRakaatMappedData {
  const _LocalRakaatMappedData({
    required this.steps,
    required this.additionalSurahOptions,
  });

  final List<RakaatStep> steps;
  final List<RakaatSurahOption> additionalSurahOptions;
}

class _LocalSurahAyah {
  const _LocalSurahAyah({
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  final String recitationArabic;
  final String translation;
  final String transliteration;
}
