import '../../domain/entities/prayer_surah.dart';

class PrayerSurahAyahModel {
  PrayerSurahAyahModel({
    required this.index,
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  factory PrayerSurahAyahModel.fromJson(Map<String, dynamic> json) {
    return PrayerSurahAyahModel(
      index: (json['index'] as num?)?.toInt() ?? 0,
      recitationArabic: (json['recitationArabic'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      transliteration: (json['transliteration'] as String?) ?? '',
    );
  }

  final int index;
  final String recitationArabic;
  final String translation;
  final String transliteration;

  Map<String, dynamic> toJson() => {
    'index': index,
    'recitationArabic': recitationArabic,
    'translation': translation,
    'transliteration': transliteration,
  };

  PrayerSurahAyah toEntity() => PrayerSurahAyah(
    index: index,
    recitationArabic: recitationArabic,
    translation: translation,
    transliteration: transliteration,
  );
}

class PrayerSurahModel {
  PrayerSurahModel({required this.code, required this.ayahs});

  factory PrayerSurahModel.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String?) ?? '';
    final rows = (json['ayahs'] as List?)?.cast<dynamic>() ?? const [];
    final byIndex = <int, PrayerSurahAyahModel>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final ayah = PrayerSurahAyahModel.fromJson(row.cast<String, dynamic>());
      byIndex[ayah.index] = ayah;
    }
    final ayahs = byIndex.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return PrayerSurahModel(code: code, ayahs: ayahs);
  }

  final String code;
  final List<PrayerSurahAyahModel> ayahs;

  Map<String, dynamic> toJson() => {
    'code': code,
    'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
  };

  PrayerSurah toEntity() => PrayerSurah(
    code: code,
    ayahs: ayahs.map((ayah) => ayah.toEntity()).toList(growable: false),
  );
}
