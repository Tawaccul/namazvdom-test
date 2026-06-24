import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/prayer/data/models/prayer_meta_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_context_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_step_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_surah_model.dart';
import 'package:prayday/features/prayer/data/models/prayer_rakaat_response_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PrayerMetaModel
  // ---------------------------------------------------------------------------
  group('PrayerMetaModel', () {
    test('fromJson parses ISO-8601 date, scope, and eTag', () {
      final model = PrayerMetaModel.fromJson({
        'lastModifiedAt': '2024-03-15T12:00:00.000Z',
        'scope': 'hanafi',
        'eTag': '"abc123"',
      });

      expect(model.lastModifiedAt, DateTime.utc(2024, 3, 15, 12));
      expect(model.scope, 'hanafi');
      expect(model.eTag, '"abc123"');
    });

    test('fromJson accepts lowercase "etag" key as fallback', () {
      final model = PrayerMetaModel.fromJson({
        'lastModifiedAt': '2024-01-01T00:00:00Z',
        'scope': 'global',
        'etag': '"lower123"',
      });
      expect(model.eTag, '"lower123"');
    });

    test('fromJson sets scope to "global" when missing', () {
      final model = PrayerMetaModel.fromJson({'lastModifiedAt': null});
      expect(model.scope, 'global');
      expect(model.lastModifiedAt, isNull);
      expect(model.eTag, isNull);
    });

    test('fromJson ignores invalid date string', () {
      final model = PrayerMetaModel.fromJson({
        'lastModifiedAt': 'not-a-date',
        'scope': 'global',
      });
      expect(model.lastModifiedAt, isNull);
    });

    test('toJson / fromJson round-trip preserves all fields', () {
      final original = PrayerMetaModel(
        lastModifiedAt: DateTime.utc(2024, 6, 1, 9, 30),
        scope: 'shafii',
        eTag: '"v2"',
      );
      final json = original.toJson();
      final restored = PrayerMetaModel.fromJson(json);

      expect(restored.lastModifiedAt, original.lastModifiedAt);
      expect(restored.scope, original.scope);
      expect(restored.eTag, original.eTag);
    });

    test('toEntity maps all fields correctly', () {
      final model = PrayerMetaModel(
        lastModifiedAt: DateTime.utc(2024, 1, 1),
        scope: 'global',
        eTag: '"x"',
      );
      final entity = model.toEntity();
      expect(entity.lastModifiedAt, model.lastModifiedAt);
      expect(entity.scope, model.scope);
      expect(entity.eTag, model.eTag);
    });
  });

  // ---------------------------------------------------------------------------
  // PrayerContextModel
  // ---------------------------------------------------------------------------
  group('PrayerContextModel', () {
    test('fromJson parses all fields', () {
      final model = PrayerContextModel.fromJson({
        'prayerCode': 'asr',
        'madhhabCode': 'hanafi',
        'genderCode': 'female',
        'languageCode': 'en',
        'rakah': 2,
        'script': 'latin',
        'totalRakahCount': 4,
      });

      expect(model.prayerCode, 'asr');
      expect(model.madhhabCode, 'hanafi');
      expect(model.genderCode, 'female');
      expect(model.languageCode, 'en');
      expect(model.rakah, 2);
      expect(model.script, 'latin');
      expect(model.totalRakahCount, 4);
    });

    test('fromJson uses safe defaults for missing fields', () {
      final model = PrayerContextModel.fromJson({});
      expect(model.prayerCode, '');
      expect(model.rakah, 1);
      expect(model.totalRakahCount, 1);
    });

    test('fromJson casts numeric rakah from double', () {
      final model = PrayerContextModel.fromJson({'rakah': 3.0, 'totalRakahCount': 4.0});
      expect(model.rakah, 3);
      expect(model.totalRakahCount, 4);
    });

    test('toJson / fromJson round-trip', () {
      final original = PrayerContextModel(
        prayerCode: 'maghrib',
        madhhabCode: 'maliki',
        genderCode: 'male',
        languageCode: 'ru',
        rakah: 1,
        script: 'cyrillic',
        totalRakahCount: 3,
      );
      final restored = PrayerContextModel.fromJson(original.toJson());
      expect(restored.prayerCode, original.prayerCode);
      expect(restored.totalRakahCount, original.totalRakahCount);
      expect(restored.script, original.script);
    });
  });

  // ---------------------------------------------------------------------------
  // PrayerStepModel
  // ---------------------------------------------------------------------------
  group('PrayerStepModel', () {
    test('fromJson parses server schema (movement/recitations)', () {
      final model = PrayerStepModel.fromJson({
        'orderIndex': 3,
        'stepCode': 'ruku',
        'recitationMode': 'silent',
        'hasRecitation': true,
        'movement': {'title': 'Ruku', 'description': 'Bow down'},
        'recitations': [
          {
            'recitationArabic': 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
            'translation': 'Glory to my Lord the Greatest',
            'transliteration': 'Subhana rabbiyal azeem',
          },
        ],
        'duas': [],
        'surahCode': null,
        'availableSurahs': [],
      });

      expect(model.orderIndex, 3);
      expect(model.stepCode, 'ruku');
      expect(model.hasRecitation, true);
      expect(model.movementDescription, 'Bow down');
      expect(model.recitations.single.recitationArabic,
          'سُبْحَانَ رَبِّيَ الْعَظِيمِ');
      expect(model.surahCode, isNull);
      expect(model.availableSurahs, isEmpty);
    });

    test('fromJson prefers dua recitations over the step recitation', () {
      final model = PrayerStepModel.fromJson({
        'orderIndex': 16,
        'stepCode': 'tashahhud',
        'recitationMode': 'silent',
        'hasRecitation': true,
        'movement': {'title': null, 'description': null},
        'recitations': [
          {'recitationArabic': 'التَّحِيَّاتُ', 'translation': '', 'transliteration': null},
        ],
        'duas': [
          {
            'duaCode': 'dua_tashahhud',
            'recitations': [
              {'recitationArabic': 'part1', 'translation': 't1', 'transliteration': 'tr1'},
              {'recitationArabic': 'part2', 'translation': 't2', 'transliteration': 'tr2'},
            ],
          },
        ],
        'surahCode': null,
        'availableSurahs': [],
      });

      expect(model.recitations.length, 2);
      expect(model.recitations.first.recitationArabic, 'part1');
      expect(model.recitations.last.transliteration, 'tr2');
    });

    test('fromJson filters out surah options with empty code', () {
      final model = PrayerStepModel.fromJson({
        'orderIndex': 1,
        'stepCode': 'additional_surah',
        'recitationMode': '',
        'hasRecitation': false,
        'content': {'movementDescription': '', 'recitationArabic': '', 'translation': '', 'transliteration': ''},
        'availableSurahs': [
          {'code': 'al-ikhlas', 'name': 'Al-Ikhlas'},
          {'code': '', 'name': 'Empty code should be filtered'},
          {'code': '   ', 'name': 'Whitespace code should be filtered'},
          {'code': 'al-kawthar', 'name': 'Al-Kawthar'},
        ],
      });

      expect(model.availableSurahs.length, 2);
      expect(model.availableSurahs.map((s) => s.code), containsAll(['al-ikhlas', 'al-kawthar']));
    });

    test('toJson / fromJson round-trip preserves surahCode', () {
      final original = PrayerStepModel.fromJson({
        'orderIndex': 5,
        'stepCode': 'qiyam',
        'recitationMode': 'aloud',
        'hasRecitation': true,
        'content': {'movementDescription': 'Stand', 'recitationArabic': '', 'translation': '', 'transliteration': ''},
        'surahCode': 'al-fatiha',
        'availableSurahs': [],
      });

      final restored = PrayerStepModel.fromJson(original.toJson());
      expect(restored.surahCode, 'al-fatiha');
      expect(restored.stepCode, 'qiyam');
      expect(restored.orderIndex, 5);
    });

    test('toEntity converts all fields including surahOptions', () {
      final model = PrayerStepModel.fromJson({
        'orderIndex': 2,
        'stepCode': 'additional_surah',
        'recitationMode': '',
        'hasRecitation': false,
        'content': {'movementDescription': '', 'recitationArabic': '', 'translation': '', 'transliteration': ''},
        'availableSurahs': [
          {'code': 'al-ikhlas', 'name': 'Al-Ikhlas'},
        ],
      });
      final entity = model.toEntity();
      expect(entity.availableSurahs.length, 1);
      expect(entity.availableSurahs.first.code, 'al-ikhlas');
    });
  });

  // ---------------------------------------------------------------------------
  // PrayerSurahModel
  // ---------------------------------------------------------------------------
  group('PrayerSurahModel', () {
    test('fromJson parses ayahs sorted by index', () {
      final model = PrayerSurahModel.fromJson({
        'code': 'al-fatiha',
        'ayahs': [
          {'index': 3, 'recitationArabic': 'verse3', 'translation': 't3', 'transliteration': 'tr3'},
          {'index': 1, 'recitationArabic': 'verse1', 'translation': 't1', 'transliteration': 'tr1'},
          {'index': 2, 'recitationArabic': 'verse2', 'translation': 't2', 'transliteration': 'tr2'},
        ],
      });

      expect(model.code, 'al-fatiha');
      expect(model.ayahs.map((a) => a.index).toList(), [1, 2, 3]);
      expect(model.ayahs[0].recitationArabic, 'verse1');
    });

    test('fromJson deduplicates ayahs with same index (last wins)', () {
      final model = PrayerSurahModel.fromJson({
        'code': 'al-ikhlas',
        'ayahs': [
          {'index': 1, 'recitationArabic': 'first', 'translation': '', 'transliteration': ''},
          {'index': 1, 'recitationArabic': 'second', 'translation': '', 'transliteration': ''},
        ],
      });

      expect(model.ayahs.length, 1);
      expect(model.ayahs[0].recitationArabic, 'second');
    });

    test('fromJson handles empty ayahs list', () {
      final model = PrayerSurahModel.fromJson({'code': 'al-kawthar', 'ayahs': []});
      expect(model.ayahs, isEmpty);
    });

    test('toJson / fromJson round-trip', () {
      final original = PrayerSurahModel.fromJson({
        'code': 'al-ikhlas',
        'ayahs': [
          {'index': 1, 'recitationArabic': 'قُلْ هُوَ اللَّهُ أَحَدٌ', 'translation': 'Say: He is God, One', 'transliteration': 'Qul huwa Allahu ahad'},
          {'index': 2, 'recitationArabic': 'اللَّهُ الصَّمَدُ', 'translation': 'God, the Everlasting', 'transliteration': 'Allahu samad'},
        ],
      });

      final restored = PrayerSurahModel.fromJson(original.toJson());
      expect(restored.code, original.code);
      expect(restored.ayahs.length, original.ayahs.length);
      expect(restored.ayahs[0].recitationArabic, original.ayahs[0].recitationArabic);
    });

    test('toEntity maps ayahs correctly', () {
      final model = PrayerSurahModel.fromJson({
        'code': 'al-fatiha',
        'ayahs': [
          {'index': 1, 'recitationArabic': 'arabic', 'translation': 'trans', 'transliteration': 'translit'},
        ],
      });
      final entity = model.toEntity();
      expect(entity.code, 'al-fatiha');
      expect(entity.ayahs.length, 1);
      expect(entity.ayahs.first.recitationArabic, 'arabic');
    });
  });

  // ---------------------------------------------------------------------------
  // PrayerRakaatResponseModel
  // ---------------------------------------------------------------------------
  group('PrayerRakaatResponseModel', () {
    Map<String, dynamic> buildJson({int rakah = 1, int totalRakahCount = 4}) => {
      'meta': {
        'lastModifiedAt': '2024-01-01T00:00:00Z',
        'scope': 'global',
        'eTag': '"v1"',
      },
      'data': {
        'context': {
          'prayerCode': 'isha',
          'madhhabCode': 'hanafi',
          'genderCode': 'male',
          'languageCode': 'ru',
          'rakah': rakah,
          'script': 'cyrillic',
          'totalRakahCount': totalRakahCount,
        },
        'steps': [
          {
            'orderIndex': 1,
            'stepCode': 'takbir',
            'recitationMode': 'silent',
            'hasRecitation': true,
            'content': {
              'movementDescription': 'Raise hands',
              'recitationArabic': 'اللَّهُ أَكْبَرُ',
              'translation': 'God is the Greatest',
              'transliteration': 'Allahu Akbar',
            },
            'availableSurahs': [],
          },
        ],
      },
    };

    test('fromJson parses context and steps', () {
      final model = PrayerRakaatResponseModel.fromJson(buildJson());
      expect(model.context.prayerCode, 'isha');
      expect(model.context.totalRakahCount, 4);
      expect(model.steps.length, 1);
      expect(model.steps.first.stepCode, 'takbir');
      expect(model.meta.eTag, '"v1"');
    });

    test('toJson / fromJson round-trip preserves all data', () {
      final original = PrayerRakaatResponseModel.fromJson(buildJson(rakah: 3, totalRakahCount: 4));
      final restored = PrayerRakaatResponseModel.fromJson(original.toJson());

      expect(restored.context.rakah, 3);
      expect(restored.context.totalRakahCount, 4);
      expect(restored.steps.length, original.steps.length);
      expect(restored.meta.eTag, original.meta.eTag);
    });

    test('toEntity maps to PrayerRakaat with correct context and steps', () {
      final model = PrayerRakaatResponseModel.fromJson(buildJson(rakah: 2, totalRakahCount: 4));
      final entity = model.toEntity();
      expect(entity.context.rakah, 2);
      expect(entity.context.totalRakahCount, 4);
      expect(entity.steps.length, 1);
      expect(entity.steps.first.stepCode, 'takbir');
    });
  });
}
