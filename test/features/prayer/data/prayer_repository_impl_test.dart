import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/core/storage/memory_key_value_store.dart';
import 'package:prayday/features/prayer/data/datasources/prayer_cache_data_source.dart';
import 'package:prayday/features/prayer/data/datasources/prayer_remote_data_source.dart';
import 'package:prayday/features/prayer/data/meta_api.dart';
import 'package:prayday/features/prayer/data/models/prayer_meta_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_rakaat_response_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_surah_model.dart';
import 'package:prayday/features/prayer/data/prayer_api.dart';
import 'package:prayday/features/prayer/data/prayer_repository_impl.dart';
import 'package:prayday/features/prayer/data/surah_api.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_request_context.dart';

// ---------------------------------------------------------------------------
// Fake API subclasses (override methods, never touch the Dio instance)
// ---------------------------------------------------------------------------

class _FakeMetaApi extends MetaApi {
  int callCount = 0;
  PrayerMetaHttpResult Function(String? ifNoneMatch)? responder;

  _FakeMetaApi() : super(Dio());

  @override
  Future<PrayerMetaHttpResult> fetchMeta({
    PrayerRequestContext? context,
    String? ifNoneMatch,
  }) async {
    callCount++;
    if (responder != null) return responder!(ifNoneMatch);
    return PrayerMetaHttpResult(
      statusCode: 200,
      body: {
        'meta': {
          'lastModifiedAt': '2024-01-01T00:00:00Z',
          'scope': 'global',
          'eTag': '"v1"',
        },
      },
      eTag: '"v1"',
    );
  }
}

class _FakePrayerApi extends PrayerApi {
  int callCount = 0;
  Object? errorToThrow;

  _FakePrayerApi() : super(Dio());

  @override
  Future<Map<String, dynamic>> fetchRakaat({
    required PrayerRequestContext context,
  }) async {
    callCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return _rakaatJson(rakah: context.rakah ?? 1, total: 4);
  }
}

class _FakeSurahApi extends SurahApi {
  int callCount = 0;
  Object? errorToThrow;

  _FakeSurahApi() : super(Dio());

  @override
  Future<Map<String, dynamic>> fetchSurah({
    required String code,
    required String languageCode,
  }) async {
    callCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return {
      'code': code,
      'ayahs': [
        {'index': 1, 'recitationArabic': 'arabic', 'translation': 'trans', 'transliteration': 'tr'},
      ],
    };
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _rakaatJson({int rakah = 1, int total = 4}) => {
      'meta': {'lastModifiedAt': '2024-01-01T00:00:00Z', 'scope': 'global', 'eTag': '"v1"'},
      'data': {
        'context': {
          'prayerCode': 'asr',
          'madhhabCode': 'hanafi',
          'genderCode': 'male',
          'languageCode': 'ru',
          'rakah': rakah,
          'script': 'cyrillic',
          'totalRakahCount': total,
        },
        'steps': [
          {
            'orderIndex': 1,
            'stepCode': 'takbir',
            'recitationMode': 'silent',
            'hasRecitation': true,
            'content': {
              'movementDescription': '',
              'recitationArabic': 'اللَّهُ أَكْبَرُ',
              'translation': 'God is Greatest',
              'transliteration': 'Allahu Akbar',
            },
            'availableSurahs': [],
          },
        ],
      },
    };

PrayerRakaatResponseModel _rakaatModel({int rakah = 1}) =>
    PrayerRakaatResponseModel.fromJson(_rakaatJson(rakah: rakah));

PrayerMetaModel _metaModel({String eTag = '"v1"', String lastModified = '2024-01-01T00:00:00Z'}) =>
    PrayerMetaModel(
      lastModifiedAt: DateTime.parse(lastModified),
      scope: 'global',
      eTag: eTag,
    );

const _ctx = PrayerRequestContext(
  prayerCode: 'asr',
  madhhabCode: 'hanafi',
  genderCode: 'male',
  languageCode: 'ru',
  rakah: 1,
  script: 'cyrillic',
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeMetaApi metaApi;
  late _FakePrayerApi prayerApi;
  late _FakeSurahApi surahApi;
  late PrayerCacheDataSource cache;
  late PrayerRepositoryImpl repo;

  setUp(() {
    metaApi = _FakeMetaApi();
    prayerApi = _FakePrayerApi();
    surahApi = _FakeSurahApi();
    final store = MemoryKeyValueStore();
    cache = PrayerCacheDataSource(store);
    repo = PrayerRepositoryImpl(
      remote: PrayerRemoteDataSource(prayerApi, metaApi, surahApi),
      cache: cache,
      metaTtl: const Duration(hours: 1),
    );
  });

  // ---------------------------------------------------------------------------
  // getRakaat — basic fetch and caching
  // ---------------------------------------------------------------------------
  group('getRakaat', () {
    test('fetches from remote and returns entity', () async {
      final rakaat = await repo.getRakaat(context: _ctx);
      expect(rakaat.context.rakah, 1);
      expect(rakaat.steps.first.stepCode, 'takbir');
      expect(prayerApi.callCount, 1);
    });

    test('returns from cache on second call without hitting remote', () async {
      await repo.getRakaat(context: _ctx);
      final second = await repo.getRakaat(context: _ctx);

      expect(second.context.rakah, 1);
      // Remote is only called once; second call is served from cache
      expect(prayerApi.callCount, 1);
    });

    test('falls back to cache when remote throws a non-404 error', () async {
      // Pre-populate cache with both meta and rakaat.
      // Meta must be present so sync sees no change and does not clear the cache.
      await cache.writeMeta(scopeKey: _ctx.scopeKey, meta: _metaModel(eTag: '"v1"'));
      await cache.writeRakaat(
        scopeKey: _ctx.scopeKey,
        cacheKey: _ctx.cacheKey,
        response: _rakaatModel(rakah: 1),
      );

      // Sync sees 304 → no cache invalidation; prayer remote then throws
      metaApi.responder = (_) => PrayerMetaHttpResult(
            statusCode: 304,
            body: const {},
            eTag: '"v1"',
          );
      prayerApi.errorToThrow = Exception('network error');

      repo = PrayerRepositoryImpl(
        remote: PrayerRemoteDataSource(prayerApi, metaApi, surahApi),
        cache: cache,
        metaTtl: const Duration(hours: 1),
      );

      final result = await repo.getRakaat(context: _ctx);
      // Cache hit — remote prayer API was never reached
      expect(result.context.rakah, 1);
      expect(prayerApi.callCount, 0);
    });

    test('rethrows when both remote and cache have no data', () async {
      prayerApi.errorToThrow = Exception('network unavailable');

      await expectLater(
        repo.getRakaat(context: _ctx),
        throwsException,
      );
    });

    test('deduplicates concurrent requests for the same cache key', () async {
      // Fire two concurrent requests for the same context
      final futures = [
        repo.getRakaat(context: _ctx),
        repo.getRakaat(context: _ctx),
      ];
      final results = await Future.wait(futures);

      // Both resolve to the same data, but remote is called only once
      expect(results[0].context.rakah, 1);
      expect(results[1].context.rakah, 1);
      expect(prayerApi.callCount, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // getSurah — caching and deduplication
  // ---------------------------------------------------------------------------
  group('getSurah', () {
    test('fetches from remote and returns entity', () async {
      final surah = await repo.getSurah(surahCode: 'al-fatiha', languageCode: 'ru');
      expect(surah.code, 'al-fatiha');
      expect(surahApi.callCount, 1);
    });

    test('returns from cache on second call', () async {
      await repo.getSurah(surahCode: 'al-fatiha', languageCode: 'ru');
      await repo.getSurah(surahCode: 'al-fatiha', languageCode: 'ru');

      expect(surahApi.callCount, 1);
    });

    test('different language codes are cached independently', () async {
      await repo.getSurah(surahCode: 'al-ikhlas', languageCode: 'ru');
      await repo.getSurah(surahCode: 'al-ikhlas', languageCode: 'en');

      expect(surahApi.callCount, 2);
    });

    test('falls back to cache when remote throws', () async {
      final model = PrayerSurahModel.fromJson({
        'code': 'al-ikhlas',
        'ayahs': [
          {'index': 1, 'recitationArabic': 'arabic', 'translation': 'trans', 'transliteration': 'tr'},
        ],
      });
      await cache.writeSurah(key: 'ru|al-ikhlas', surah: model);

      surahApi.errorToThrow = Exception('offline');
      repo = PrayerRepositoryImpl(
        remote: PrayerRemoteDataSource(prayerApi, metaApi, surahApi),
        cache: cache,
      );

      final result = await repo.getSurah(surahCode: 'al-ikhlas', languageCode: 'ru');
      expect(result.code, 'al-ikhlas');
    });

    test('deduplicates concurrent requests for the same surah', () async {
      final futures = [
        repo.getSurah(surahCode: 'al-kawthar', languageCode: 'en'),
        repo.getSurah(surahCode: 'al-kawthar', languageCode: 'en'),
      ];
      await Future.wait(futures);

      expect(surahApi.callCount, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Meta sync — cache invalidation
  // ---------------------------------------------------------------------------
  group('meta sync / cache invalidation', () {
    test('clears rakaat cache when remote meta lastModifiedAt changes', () async {
      // First call: meta v1, rakaat is fetched and cached
      await repo.getRakaat(context: _ctx);
      expect(prayerApi.callCount, 1);

      // Advance meta to v2 (new lastModifiedAt)
      metaApi.responder = (_) => PrayerMetaHttpResult(
            statusCode: 200,
            body: {
              'meta': {
                'lastModifiedAt': '2025-06-01T00:00:00Z',
                'scope': 'global',
                'eTag': '"v2"',
              },
            },
            eTag: '"v2"',
          );

      // New repo instance to reset in-memory sync state
      repo = PrayerRepositoryImpl(
        remote: PrayerRemoteDataSource(prayerApi, metaApi, surahApi),
        cache: cache,
        metaTtl: const Duration(hours: 1),
      );

      // Second call: meta changed → cache is cleared → remote is called again
      await repo.getRakaat(context: _ctx);
      expect(prayerApi.callCount, 2);
    });

    test('does not clear cache when remote returns 304 Not Modified', () async {
      // Pre-populate cache with meta and rakaat
      await cache.writeMeta(scopeKey: _ctx.scopeKey, meta: _metaModel(eTag: '"v1"'));
      await cache.writeRakaat(
        scopeKey: _ctx.scopeKey,
        cacheKey: _ctx.cacheKey,
        response: _rakaatModel(),
      );

      // Remote responds 304
      metaApi.responder = (_) => PrayerMetaHttpResult(
            statusCode: 304,
            body: const {},
            eTag: '"v1"',
          );

      repo = PrayerRepositoryImpl(
        remote: PrayerRemoteDataSource(prayerApi, metaApi, surahApi),
        cache: cache,
        metaTtl: const Duration(hours: 1),
      );

      final result = await repo.getRakaat(context: _ctx);
      // Cache hit — remote prayer API never called
      expect(prayerApi.callCount, 0);
      expect(result.context.rakah, 1);
    });

    test('sync for same scope runs only once even under concurrent calls', () async {
      final futures = [
        repo.getRakaat(context: _ctx),
        repo.getRakaat(context: _ctx),
        repo.getRakaat(context: _ctx),
      ];
      await Future.wait(futures);

      // Meta is fetched only once despite three concurrent calls
      expect(metaApi.callCount, 1);
    });
  });
}
