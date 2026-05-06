import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/stage/models/rakaat_models.dart';
import 'package:prayday/features/stage/parts/stage_additional_surah_helper.dart';

RakaatStep _step({
  String stepCode = '',
  String additionalSurahOptionCode = '',
  String surahCode = '',
}) => RakaatStep(
  orderIndex: 1,
  title: '',
  movementDescription: '',
  arabic: '',
  transliteration: '',
  translation: '',
  stepCode: stepCode,
  surahCode: surahCode,
  additionalSurahOptionCode: additionalSurahOptionCode,
);

void main() {
  group('StageAdditionalSurahHelper.isAdditionalSurahStep', () {
    test('returns false for null step', () {
      expect(StageAdditionalSurahHelper.isAdditionalSurahStep(null), isFalse);
    });

    test('returns true when stepCode == additional_surah', () {
      expect(
        StageAdditionalSurahHelper.isAdditionalSurahStep(
          _step(stepCode: 'additional_surah'),
        ),
        isTrue,
      );
    });

    test('case-insensitive match on stepCode', () {
      expect(
        StageAdditionalSurahHelper.isAdditionalSurahStep(
          _step(stepCode: 'ADDITIONAL_SURAH'),
        ),
        isTrue,
      );
    });

    test('returns true when additionalSurahOptionCode is non-empty', () {
      expect(
        StageAdditionalSurahHelper.isAdditionalSurahStep(
          _step(additionalSurahOptionCode: 'al_ikhlas'),
        ),
        isTrue,
      );
    });

    test('returns false for plain step', () {
      expect(
        StageAdditionalSurahHelper.isAdditionalSurahStep(
          _step(stepCode: 'fatiha'),
        ),
        isFalse,
      );
    });
  });

  group('StageAdditionalSurahHelper.selectedIndexForStep', () {
    const options = [
      RakaatSurahOption(code: 'al_kafirun', label: 'Al-Kafirun'),
      RakaatSurahOption(code: 'al_ikhlas', label: 'Al-Ikhlas'),
      RakaatSurahOption(code: 'al_nas', label: 'An-Nas'),
    ];

    test('returns 0 for empty options', () {
      expect(
        StageAdditionalSurahHelper.selectedIndexForStep(
          options: const [],
          selectedAdditionalSurahCode: 'al_ikhlas',
          step: null,
        ),
        0,
      );
    });

    test('prefers code from current step', () {
      final result = StageAdditionalSurahHelper.selectedIndexForStep(
        options: options,
        selectedAdditionalSurahCode: 'al_kafirun',
        step: _step(additionalSurahOptionCode: 'al_nas'),
      );
      expect(result, 2);
    });

    test('falls back to selectedAdditionalSurahCode when step has no code', () {
      final result = StageAdditionalSurahHelper.selectedIndexForStep(
        options: options,
        selectedAdditionalSurahCode: 'al_ikhlas',
        step: null,
      );
      expect(result, 1);
    });

    test('prefers al_ikhlas when present and no explicit selection', () {
      final result = StageAdditionalSurahHelper.selectedIndexForStep(
        options: options,
        selectedAdditionalSurahCode: null,
        step: null,
      );
      expect(result, 1);
    });

    test('returns 0 when nothing matches', () {
      final result = StageAdditionalSurahHelper.selectedIndexForStep(
        options: const [
          RakaatSurahOption(code: 'al_kafirun', label: 'Al-Kafirun'),
        ],
        selectedAdditionalSurahCode: 'unknown',
        step: null,
      );
      expect(result, 0);
    });
  });
}
