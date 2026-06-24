import 'package:flutter/foundation.dart';

@immutable
class PrayerStepContent {
  const PrayerStepContent({
    required this.movementDescription,
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  final String movementDescription;
  final String recitationArabic;
  final String translation;
  final String transliteration;
}

/// A single recitation entry of a step. A step may carry several of these
/// (e.g. tashahhud / salawat are split into parts on the server).
@immutable
class PrayerStepRecitation {
  const PrayerStepRecitation({
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  final String recitationArabic;
  final String translation;
  final String transliteration;
}

/// A surah embedded directly in a step by the server, with its ayahs in
/// [recitations]. Obligatory surahs (al_fatiha) come as a single entry;
/// the `additional_surah` step carries the selectable options here.
@immutable
class PrayerStepSurahContent {
  const PrayerStepSurahContent({
    required this.code,
    required this.name,
    required this.recitations,
  });

  final String code;
  final String name;
  final List<PrayerStepRecitation> recitations;
}

@immutable
class PrayerStep {
  const PrayerStep({
    required this.orderIndex,
    required this.stepCode,
    required this.recitationMode,
    required this.hasRecitation,
    required this.content,
    this.recitations = const [],
    this.surahs = const [],
    this.surahCode,
    this.availableSurahs = const [],
  });

  final int orderIndex;
  final String stepCode;
  final String recitationMode;
  final bool hasRecitation;
  final PrayerStepContent content;

  /// All recitation entries for this step (already flattened from the
  /// server's `recitations[]` / `duas[]`). May be empty for movement-only
  /// steps. `content` holds the first entry for backward compatibility.
  final List<PrayerStepRecitation> recitations;

  /// Surahs embedded in the step by the server. For obligatory surahs this is
  /// the surah to recite (al_fatiha); for `additional_surah` these are the
  /// selectable options.
  final List<PrayerStepSurahContent> surahs;
  final String? surahCode;
  final List<PrayerStepSurahOption> availableSurahs;
}

@immutable
class PrayerStepSurahOption {
  const PrayerStepSurahOption({required this.code, required this.name});

  final String code;
  final String name;
}
