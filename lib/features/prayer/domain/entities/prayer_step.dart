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

@immutable
class PrayerStep {
  const PrayerStep({
    required this.orderIndex,
    required this.stepCode,
    required this.recitationMode,
    required this.hasRecitation,
    required this.content,
    this.surahCode,
    this.availableSurahs = const [],
  });

  final int orderIndex;
  final String stepCode;
  final String recitationMode;
  final bool hasRecitation;
  final PrayerStepContent content;
  final String? surahCode;
  final List<PrayerStepSurahOption> availableSurahs;
}

@immutable
class PrayerStepSurahOption {
  const PrayerStepSurahOption({required this.code, required this.name});

  final String code;
  final String name;
}
