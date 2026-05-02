import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_context.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_meta.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_rakaat.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_request_context.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_surah.dart';
import 'package:prayday/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:prayday/features/prayer/domain/usecases/get_prayer_rakaats.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRepository implements PrayerRepository {
  /// Controls totalRakahCount returned by the first rakaat.
  final int totalRakahCount;

  /// Records the rakah numbers that were requested.
  final List<int> requestedRakahs = [];

  _FakeRepository({required this.totalRakahCount});

  @override
  Future<PrayerRakaat> getRakaat({required PrayerRequestContext context}) async {
    final rakah = context.rakah ?? 1;
    requestedRakahs.add(rakah);
    return PrayerRakaat(
      context: PrayerContext(
        prayerCode: context.prayerCode ?? '',
        madhhabCode: context.madhhabCode ?? '',
        genderCode: context.genderCode ?? '',
        languageCode: context.languageCode ?? '',
        rakah: rakah,
        script: context.script ?? '',
        totalRakahCount: totalRakahCount,
      ),
      steps: const [],
      meta: const PrayerMeta(lastModifiedAt: null, scope: 'global', eTag: null),
    );
  }

  @override
  Future<PrayerMeta> getRemoteMeta({PrayerRequestContext? context}) async {
    return const PrayerMeta(lastModifiedAt: null, scope: 'global', eTag: null);
  }

  @override
  Future<PrayerSurah> getSurah({
    required String surahCode,
    required String languageCode,
  }) async {
    return PrayerSurah(code: surahCode, ayahs: const []);
  }
}

const _baseContext = PrayerRequestContext(
  prayerCode: 'asr',
  madhhabCode: 'hanafi',
  genderCode: 'male',
  languageCode: 'ru',
  rakah: 1,
  script: 'cyrillic',
);

void main() {
  group('GetPrayerRakaats', () {
    test('returns only the first rakaat when totalRakahCount is 1', () async {
      final repo = _FakeRepository(totalRakahCount: 1);
      final result = await GetPrayerRakaats(repo)(baseContext: _baseContext);

      expect(result.length, 1);
      expect(result.first.context.rakah, 1);
      // Only one request made
      expect(repo.requestedRakahs, [1]);
    });

    test('fetches all rakaats for a 4-rakaat prayer', () async {
      final repo = _FakeRepository(totalRakahCount: 4);
      final result = await GetPrayerRakaats(repo)(baseContext: _baseContext);

      expect(result.length, 4);
      expect(result.map((r) => r.context.rakah).toList(), [1, 2, 3, 4]);
    });

    test('rakaats are sorted by rakah number', () async {
      final repo = _FakeRepository(totalRakahCount: 3);
      final result = await GetPrayerRakaats(repo)(baseContext: _baseContext);

      final rakahs = result.map((r) => r.context.rakah).toList();
      expect(rakahs, orderedEquals([1, 2, 3]));
    });

    test('each rakaat request uses the correct rakah number', () async {
      final repo = _FakeRepository(totalRakahCount: 3);
      await GetPrayerRakaats(repo)(baseContext: _baseContext);

      expect(repo.requestedRakahs, containsAll([1, 2, 3]));
      expect(repo.requestedRakahs.length, 3);
    });

    test('clamps totalRakahCount to 20 to prevent runaway requests', () async {
      final repo = _FakeRepository(totalRakahCount: 99);
      final result = await GetPrayerRakaats(repo)(baseContext: _baseContext);

      expect(result.length, 20);
      expect(repo.requestedRakahs.length, 20);
    });

    test('copyWith sets the correct rakah per request', () async {
      final repo = _FakeRepository(totalRakahCount: 2);
      await GetPrayerRakaats(repo)(baseContext: _baseContext);

      // Rakah 1 is fetched first (sequential), 2 is fetched via Future.wait
      expect(repo.requestedRakahs, containsAll([1, 2]));
    });
  });
}
