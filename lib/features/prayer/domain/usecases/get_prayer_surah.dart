import '../entities/prayer_surah.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerSurah {
  GetPrayerSurah(this._repository);

  final PrayerRepository _repository;

  Future<PrayerSurah> call({
    required String surahCode,
    required String languageCode,
  }) {
    return _repository.getSurah(
      surahCode: surahCode,
      languageCode: languageCode,
    );
  }
}
