class QuranAyah {
  const QuranAyah({
    required this.surahId,
    required this.ayahId,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.ayahCount,
    required this.ayahAr,
    required this.ayahEn,
    required this.ayahTr,
    required this.reciterId,
    required this.reciterName,
    required this.audioUrl,
  });

  final int surahId;
  final int ayahId;
  final String surahNameAr;
  final String surahNameEn;
  final int ayahCount;
  final String ayahAr;
  final String ayahEn;
  final String ayahTr;
  final String reciterId;
  final String reciterName;
  final String audioUrl;

  static QuranAyah fromDatasetRow(Map<String, dynamic> row) {
    final audioList = (row['audio'] as List?)?.cast<dynamic>() ?? const [];
    final audio0 = audioList.isNotEmpty ? (audioList.first as Map?) : null;
    final audioUrl = (audio0?['src'] as String?) ?? '';

    return QuranAyah(
      surahId: (row['surah_id'] as num).toInt(),
      ayahId: (row['ayah_id'] as num).toInt(),
      surahNameAr: (row['surah_name_ar'] as String?) ?? '',
      surahNameEn: (row['surah_name_en'] as String?) ?? '',
      ayahCount: (row['ayah_count'] as num).toInt(),
      ayahAr: (row['ayah_ar'] as String?) ?? '',
      ayahEn: (row['ayah_en'] as String?) ?? '',
      ayahTr: (row['ayah_tr'] as String?) ?? '',
      reciterId: (row['reciter_id'] as String?) ?? '',
      reciterName: (row['reciter_name'] as String?) ?? '',
      audioUrl: audioUrl,
    );
  }
}
