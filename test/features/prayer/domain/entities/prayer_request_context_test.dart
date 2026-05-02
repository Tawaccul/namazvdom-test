import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/prayer/domain/entities/prayer_request_context.dart';

void main() {
  group('PrayerRequestContext', () {
    group('scopeKey', () {
      test('builds pipe-delimited key from all fields', () {
        const ctx = PrayerRequestContext(
          prayerCode: 'fajr',
          madhhabCode: 'hanafi',
          genderCode: 'male',
          languageCode: 'ru',
          script: 'cyrillic',
        );
        expect(ctx.scopeKey, 'fajr|hanafi|male|ru|cyrillic');
      });

      test('uses empty strings for null fields', () {
        const ctx = PrayerRequestContext();
        expect(ctx.scopeKey, '||||');
      });

      test('partial nulls produce correct key', () {
        const ctx = PrayerRequestContext(
          prayerCode: 'dhuhr',
          languageCode: 'en',
        );
        // order: prayerCode|madhhabCode|genderCode|languageCode|script
        expect(ctx.scopeKey, 'dhuhr|||en|');
      });
    });

    group('cacheKey', () {
      test('appends rakah to scopeKey', () {
        const ctx = PrayerRequestContext(
          prayerCode: 'asr',
          madhhabCode: 'shafii',
          genderCode: 'female',
          languageCode: 'en',
          script: 'latin',
          rakah: 2,
        );
        expect(ctx.cacheKey, 'asr|shafii|female|en|latin|rakah=2');
      });

      test('uses empty string when rakah is null', () {
        const ctx = PrayerRequestContext(prayerCode: 'isha');
        // scopeKey has 5 segments (4 pipes), cacheKey appends one more pipe + rakah
        expect(ctx.cacheKey, 'isha|||||rakah=');
      });
    });

    group('copyWith', () {
      const base = PrayerRequestContext(
        prayerCode: 'maghrib',
        madhhabCode: 'hanafi',
        genderCode: 'male',
        languageCode: 'ru',
        rakah: 1,
        script: 'cyrillic',
      );

      test('overrides only specified fields', () {
        final updated = base.copyWith(rakah: 3, languageCode: 'en');
        expect(updated.prayerCode, 'maghrib');
        expect(updated.madhhabCode, 'hanafi');
        expect(updated.genderCode, 'male');
        expect(updated.languageCode, 'en');
        expect(updated.rakah, 3);
        expect(updated.script, 'cyrillic');
      });

      test('preserves all original values when called with no args', () {
        final copy = base.copyWith();
        expect(copy.prayerCode, base.prayerCode);
        expect(copy.madhhabCode, base.madhhabCode);
        expect(copy.genderCode, base.genderCode);
        expect(copy.languageCode, base.languageCode);
        expect(copy.rakah, base.rakah);
        expect(copy.script, base.script);
      });

      test('each rakah produces distinct cacheKey', () {
        final keys = {1, 2, 3, 4}.map((r) => base.copyWith(rakah: r).cacheKey).toSet();
        expect(keys.length, 4);
      });
    });
  });
}
