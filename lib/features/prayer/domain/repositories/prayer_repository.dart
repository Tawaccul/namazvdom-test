import '../entities/prayer_meta.dart';
import '../entities/prayer_rakaat.dart';
import '../entities/prayer_request_context.dart';
import '../entities/prayer_surah.dart';

abstract class PrayerRepository {
  Future<PrayerMeta> getRemoteMeta({PrayerRequestContext? context});

  Future<PrayerRakaat> getRakaat({required PrayerRequestContext context});

  Future<PrayerSurah> getSurah({
    required String surahCode,
    required String languageCode,
  });
}
