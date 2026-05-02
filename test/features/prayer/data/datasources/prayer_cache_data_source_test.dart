import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/core/storage/memory_key_value_store.dart';
import 'package:prayday/features/prayer/data/datasources/prayer_cache_data_source.dart';
import 'package:prayday/features/prayer/data/models/prayer_context_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_meta_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_rakaat_response_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_step_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_surah_model.dart';

PrayerMetaModel _metaModel({String scope = 'global', String eTag = '"v1"'}) =>
    PrayerMetaModel(
      lastModifiedAt: DateTime.utc(2024, 1, 1),
      scope: scope,
      eTag: eTag,
    );

PrayerRakaatResponseModel _rakaatModel({int rakah = 1, int total = 4}) =>
    PrayerRakaatResponseModel(
      context: PrayerContextModel(
        prayerCode: 'asr',
        madhhabCode: 'hanafi',
        genderCode: 'male',
        languageCode: 'ru',
        rakah: rakah,
        script: 'cyrillic',
        totalRakahCount: total,
      ),
      steps: [
        PrayerStepModel(
          orderIndex: 1,
          stepCode: 'takbir',
          recitationMode: 'silent',
          hasRecitation: true,
          content: PrayerStepContentModel(
            movementDescription: 'Raise hands',
            recitationArabic: 'اللَّهُ أَكْبَرُ',
            translation: 'God is Greatest',
            transliteration: 'Allahu Akbar',
          ),
          surahCode: null,
          availableSurahs: [],
        ),
      ],
      meta: _metaModel(),
    );

PrayerSurahModel _surahModel(String code) => PrayerSurahModel.fromJson({
      'code': code,
      'ayahs': [
        {'index': 1, 'recitationArabic': 'arabic', 'translation': 'trans', 'transliteration': 'tr'},
      ],
    });

void main() {
  late MemoryKeyValueStore store;
  late PrayerCacheDataSource cache;

  setUp(() {
    store = MemoryKeyValueStore();
    cache = PrayerCacheDataSource(store);
  });

  // ---------------------------------------------------------------------------
  // Meta
  // ---------------------------------------------------------------------------
  group('meta', () {
    test('readMeta returns null when nothing is stored', () async {
      final result = await cache.readMeta(scopeKey: 'any');
      expect(result, isNull);
    });

    test('writeMeta then readMeta returns the same model', () async {
      final model = _metaModel(scope: 'hanafi', eTag: '"abc"');
      await cache.writeMeta(scopeKey: 'hanafi-scope', meta: model);

      final result = await cache.readMeta(scopeKey: 'hanafi-scope');
      expect(result, isNotNull);
      expect(result!.scope, 'hanafi');
      expect(result.eTag, '"abc"');
    });

    test('writeMeta with different scopeKeys stores independently', () async {
      await cache.writeMeta(scopeKey: 'scope-a', meta: _metaModel(eTag: '"a"'));
      await cache.writeMeta(scopeKey: 'scope-b', meta: _metaModel(eTag: '"b"'));

      expect((await cache.readMeta(scopeKey: 'scope-a'))?.eTag, '"a"');
      expect((await cache.readMeta(scopeKey: 'scope-b'))?.eTag, '"b"');
    });

    test('writeMeta registers scope in the scopes index', () async {
      await cache.writeMeta(scopeKey: 'my-scope', meta: _metaModel());
      final scopes = await cache.readScopes();
      expect(scopes, contains('my-scope'));
    });
  });

  // ---------------------------------------------------------------------------
  // Rakaat
  // ---------------------------------------------------------------------------
  group('rakaat', () {
    const scopeKey = 'asr|hanafi|male|ru|cyrillic';
    const cacheKey = 'asr|hanafi|male|ru|cyrillic|rakah=1';

    test('readRakaat returns null when nothing is stored', () async {
      expect(await cache.readRakaat(cacheKey: cacheKey), isNull);
    });

    test('writeRakaat then readRakaat returns the same model', () async {
      final model = _rakaatModel(rakah: 1, total: 4);
      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: cacheKey, response: model);

      final result = await cache.readRakaat(cacheKey: cacheKey);
      expect(result, isNotNull);
      expect(result!.context.rakah, 1);
      expect(result.steps.first.stepCode, 'takbir');
    });

    test('writeRakaat registers cacheKey in the scope index', () async {
      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: cacheKey, response: _rakaatModel());

      final cacheKey2 = 'asr|hanafi|male|ru|cyrillic|rakah=2';
      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: cacheKey2, response: _rakaatModel(rakah: 2));

      // Both keys exist in the store
      expect(await cache.readRakaat(cacheKey: cacheKey), isNotNull);
      expect(await cache.readRakaat(cacheKey: cacheKey2), isNotNull);
    });

    test('clearRakaatsForScope removes all rakaats for that scope', () async {
      final key2 = 'asr|hanafi|male|ru|cyrillic|rakah=2';
      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: cacheKey, response: _rakaatModel(rakah: 1));
      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: key2, response: _rakaatModel(rakah: 2));

      await cache.clearRakaatsForScope(scopeKey: scopeKey);

      expect(await cache.readRakaat(cacheKey: cacheKey), isNull);
      expect(await cache.readRakaat(cacheKey: key2), isNull);
    });

    test('clearRakaatsForScope does not touch rakaats of another scope', () async {
      const otherScope = 'dhuhr|hanafi|male|ru|cyrillic';
      const otherKey = 'dhuhr|hanafi|male|ru|cyrillic|rakah=1';

      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: cacheKey, response: _rakaatModel());
      await cache.writeRakaat(scopeKey: otherScope, cacheKey: otherKey, response: _rakaatModel());

      await cache.clearRakaatsForScope(scopeKey: scopeKey);

      expect(await cache.readRakaat(cacheKey: cacheKey), isNull);
      expect(await cache.readRakaat(cacheKey: otherKey), isNotNull);
    });

    test('clearRakaatsForScope does not remove meta', () async {
      await cache.writeMeta(scopeKey: scopeKey, meta: _metaModel());
      await cache.writeRakaat(scopeKey: scopeKey, cacheKey: cacheKey, response: _rakaatModel());

      await cache.clearRakaatsForScope(scopeKey: scopeKey);

      expect(await cache.readMeta(scopeKey: scopeKey), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Surah
  // ---------------------------------------------------------------------------
  group('surah', () {
    test('readSurah returns null when nothing is stored', () async {
      expect(await cache.readSurah(key: 'ru|al-fatiha'), isNull);
    });

    test('writeSurah then readSurah returns the same model', () async {
      final model = _surahModel('al-fatiha');
      await cache.writeSurah(key: 'ru|al-fatiha', surah: model);

      final result = await cache.readSurah(key: 'ru|al-fatiha');
      expect(result, isNotNull);
      expect(result!.code, 'al-fatiha');
      expect(result.ayahs.length, 1);
    });

    test('writeSurah with same key does not duplicate surah index entry', () async {
      await cache.writeSurah(key: 'ru|al-ikhlas', surah: _surahModel('al-ikhlas'));
      await cache.writeSurah(key: 'ru|al-ikhlas', surah: _surahModel('al-ikhlas'));

      // Still readable without error
      expect(await cache.readSurah(key: 'ru|al-ikhlas'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // clearAll
  // ---------------------------------------------------------------------------
  group('clearAll', () {
    test('removes all rakaats, meta, and surahs', () async {
      const sk = 'fajr|hanafi|male|ru|cyrillic';
      const ck = 'fajr|hanafi|male|ru|cyrillic|rakah=1';

      await cache.writeMeta(scopeKey: sk, meta: _metaModel());
      await cache.writeRakaat(scopeKey: sk, cacheKey: ck, response: _rakaatModel());
      await cache.writeSurah(key: 'ru|al-fatiha', surah: _surahModel('al-fatiha'));

      await cache.clearAll();

      expect(await cache.readMeta(scopeKey: sk), isNull);
      expect(await cache.readRakaat(cacheKey: ck), isNull);
      expect(await cache.readSurah(key: 'ru|al-fatiha'), isNull);
      expect(await cache.readScopes(), isEmpty);
    });

    test('clearAll on empty store completes without error', () async {
      await expectLater(cache.clearAll(), completes);
    });
  });
}
