import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/stage/models/rakaat_models.dart';
import 'package:prayday/features/stage/parts/stage_step_data_helper.dart';

RakaatStep _step({
  required int orderIndex,
  String arabic = '',
  String translation = '',
  String transliteration = '',
  String title = '',
  String stepCode = '',
}) => RakaatStep(
  orderIndex: orderIndex,
  title: title,
  movementDescription: '',
  arabic: arabic,
  transliteration: transliteration,
  translation: translation,
  stepCode: stepCode,
);

RakaatData _rakaat({required int number, required List<RakaatStep> steps}) =>
    RakaatData(number: number, imageAsset: '', steps: steps);

void main() {
  group('StageStepDataHelper.stepCountForRakaat', () {
    test('returns 0 for empty rakaats', () {
      expect(
        StageStepDataHelper.stepCountForRakaat(rakaats: const [], rakaatIndex: 0),
        0,
      );
    });

    test('counts unique orderIndexes only (duplicates merge)', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [
            _step(orderIndex: 1),
            _step(orderIndex: 1, arabic: 'ayah1'),
            _step(orderIndex: 2),
            _step(orderIndex: 3),
          ],
        ),
      ];
      expect(
        StageStepDataHelper.stepCountForRakaat(rakaats: rakaats, rakaatIndex: 0),
        3,
      );
    });

    test('clamps rakaatIndex out of range', () {
      final rakaats = [
        _rakaat(number: 1, steps: [_step(orderIndex: 1)]),
      ];
      expect(
        StageStepDataHelper.stepCountForRakaat(
          rakaats: rakaats,
          rakaatIndex: 99,
        ),
        1,
      );
    });
  });

  group('StageStepDataHelper.currentStepOrderIndexes', () {
    test('returns sorted unique orderIndexes', () {
      final steps = [
        _step(orderIndex: 3),
        _step(orderIndex: 1),
        _step(orderIndex: 1),
        _step(orderIndex: 2),
      ];
      expect(
        StageStepDataHelper.currentStepOrderIndexes(currentRakaatSteps: steps),
        [1, 2, 3],
      );
    });

    test('returns empty for empty steps', () {
      expect(
        StageStepDataHelper.currentStepOrderIndexes(
          currentRakaatSteps: const [],
        ),
        isEmpty,
      );
    });
  });

  group('StageStepDataHelper.currentRecitationEntries', () {
    test('keeps entries with arabic/translation/transliteration', () {
      final entries = [
        _step(orderIndex: 1),
        _step(orderIndex: 1, arabic: 'allah'),
        _step(orderIndex: 1, translation: 'God'),
        _step(orderIndex: 1, transliteration: 'allahu'),
      ];
      final result = StageStepDataHelper.currentRecitationEntries(
        currentStepEntries: entries,
      );
      expect(result.length, 3);
    });

    test('drops empty entries', () {
      final entries = [_step(orderIndex: 1), _step(orderIndex: 1)];
      expect(
        StageStepDataHelper.currentRecitationEntries(
          currentStepEntries: entries,
        ),
        isEmpty,
      );
    });
  });

  group('StageStepDataHelper.hasNextStageStep', () {
    test('true when not at last step within rakaat', () {
      expect(
        StageStepDataHelper.hasNextStageStep(
          currentStepOrderIndexes: const [1, 2, 3],
          clampedStepIndex: 0,
          rakaats: [_rakaat(number: 1, steps: [_step(orderIndex: 1)])],
          rakaatIndex: 0,
        ),
        isTrue,
      );
    });

    test('true at last step but another rakaat exists', () {
      expect(
        StageStepDataHelper.hasNextStageStep(
          currentStepOrderIndexes: const [1, 2],
          clampedStepIndex: 1,
          rakaats: [
            _rakaat(number: 1, steps: [_step(orderIndex: 1)]),
            _rakaat(number: 2, steps: [_step(orderIndex: 1)]),
          ],
          rakaatIndex: 0,
        ),
        isTrue,
      );
    });

    test('false at last step of last rakaat', () {
      expect(
        StageStepDataHelper.hasNextStageStep(
          currentStepOrderIndexes: const [1, 2],
          clampedStepIndex: 1,
          rakaats: [_rakaat(number: 1, steps: [_step(orderIndex: 1)])],
          rakaatIndex: 0,
        ),
        isFalse,
      );
    });

    test('false when current step orders empty', () {
      expect(
        StageStepDataHelper.hasNextStageStep(
          currentStepOrderIndexes: const [],
          clampedStepIndex: 0,
          rakaats: [_rakaat(number: 1, steps: [_step(orderIndex: 1)])],
          rakaatIndex: 0,
        ),
        isFalse,
      );
    });
  });

  group('StageStepDataHelper.hasPrevStageStep', () {
    test('true when not at first step', () {
      expect(
        StageStepDataHelper.hasPrevStageStep(
          currentStepOrderIndexes: const [1, 2, 3],
          clampedStepIndex: 1,
          rakaats: [_rakaat(number: 1, steps: [_step(orderIndex: 1)])],
          rakaatIndex: 0,
        ),
        isTrue,
      );
    });

    test('true at first step but earlier rakaat exists', () {
      expect(
        StageStepDataHelper.hasPrevStageStep(
          currentStepOrderIndexes: const [1, 2],
          clampedStepIndex: 0,
          rakaats: [
            _rakaat(number: 1, steps: [_step(orderIndex: 1)]),
            _rakaat(number: 2, steps: [_step(orderIndex: 1)]),
          ],
          rakaatIndex: 1,
        ),
        isTrue,
      );
    });

    test('false at first step of first rakaat', () {
      expect(
        StageStepDataHelper.hasPrevStageStep(
          currentStepOrderIndexes: const [1, 2],
          clampedStepIndex: 0,
          rakaats: [_rakaat(number: 1, steps: [_step(orderIndex: 1)])],
          rakaatIndex: 0,
        ),
        isFalse,
      );
    });
  });

  group('StageStepDataHelper.allStagePages', () {
    test('builds flat page list across rakaats', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2)],
        ),
        _rakaat(
          number: 2,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2), _step(orderIndex: 3)],
        ),
      ];
      final pages = StageStepDataHelper.allStagePages(
        rakaats: rakaats,
        stepOrderIndexesForRakaatIndex: (i) =>
            StageStepDataHelper.stepOrderIndexesForRakaatIndex(
              rakaats: rakaats,
              rakaatIndex: i,
            ),
      );
      expect(pages.length, 5);
      expect(pages.first.rakaatIndex, 0);
      expect(pages.first.stepIndex, 0);
      expect(pages.last.rakaatIndex, 1);
      expect(pages.last.stepIndex, 2);
    });

    test('returns empty for empty rakaats', () {
      expect(
        StageStepDataHelper.allStagePages(
          rakaats: const [],
          stepOrderIndexesForRakaatIndex: (_) => const [],
        ),
        isEmpty,
      );
    });
  });

  group('StageStepDataHelper.currentFlatPageIndex', () {
    test('returns 0 when pages empty', () {
      expect(
        StageStepDataHelper.currentFlatPageIndex(
          allStagePages: const [],
          rakaatIndex: 0,
          clampedStepIndex: 0,
        ),
        0,
      );
    });

    test('returns 0 when page not found', () {
      final rakaats = [
        _rakaat(number: 1, steps: [_step(orderIndex: 1)]),
      ];
      final pages = StageStepDataHelper.allStagePages(
        rakaats: rakaats,
        stepOrderIndexesForRakaatIndex: (i) =>
            StageStepDataHelper.stepOrderIndexesForRakaatIndex(
              rakaats: rakaats,
              rakaatIndex: i,
            ),
      );
      expect(
        StageStepDataHelper.currentFlatPageIndex(
          allStagePages: pages,
          rakaatIndex: 5,
          clampedStepIndex: 5,
        ),
        0,
      );
    });

    test('returns correct flat index for rakaat+step', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2)],
        ),
        _rakaat(
          number: 2,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2)],
        ),
      ];
      final pages = StageStepDataHelper.allStagePages(
        rakaats: rakaats,
        stepOrderIndexesForRakaatIndex: (i) =>
            StageStepDataHelper.stepOrderIndexesForRakaatIndex(
              rakaats: rakaats,
              rakaatIndex: i,
            ),
      );
      expect(
        StageStepDataHelper.currentFlatPageIndex(
          allStagePages: pages,
          rakaatIndex: 1,
          clampedStepIndex: 0,
        ),
        2,
      );
    });
  });
}
