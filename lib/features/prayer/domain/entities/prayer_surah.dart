import 'package:flutter/foundation.dart';

@immutable
class PrayerSurahAyah {
  const PrayerSurahAyah({
    required this.index,
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  final int index;
  final String recitationArabic;
  final String translation;
  final String transliteration;
}

@immutable
class PrayerSurah {
  const PrayerSurah({required this.code, required this.ayahs});

  final String code;
  final List<PrayerSurahAyah> ayahs;
}
