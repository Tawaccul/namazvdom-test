import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/stage/models/rakaat_models.dart';
import 'package:prayday/features/stage/parts/stage_step_screen_flow_helper.dart';

RakaatStep _step({required int orderIndex, String title = ''}) => RakaatStep(
  orderIndex: orderIndex,
  title: title,
  movementDescription: '',
  arabic: '',
  transliteration: '',
  translation: '',
  stepCode: '',
);

RakaatData _rakaat({required int number, required List<RakaatStep> steps}) =>
    RakaatData(number: number, imageAsset: '', steps: steps);

void main() {
  group('StageStepScreenFlowHelper.displayStepProgressFor', () {
    test('returns 1/1 for empty rakaats', () {
      final result = StageStepScreenFlowHelper.displayStepProgressFor(
        rakaats: const [],
        prayerCode: 'dhuhr',
        rakaatIndex: 0,
        stepIndex: 0,
        stepOrderIndexesForRakaatIndex: (_) => const [],
      );
      expect(result.current, 1);
      expect(result.total, 1);
    });

    test('non-Fajr prayer returns (clampedStep+1)/total', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [
            _step(orderIndex: 1),
            _step(orderIndex: 2),
            _step(orderIndex: 3),
          ],
        ),
      ];
      final result = StageStepScreenFlowHelper.displayStepProgressFor(
        rakaats: rakaats,
        prayerCode: 'dhuhr',
        rakaatIndex: 0,
        stepIndex: 1,
        stepOrderIndexesForRakaatIndex: (_) => const [1, 2, 3],
      );
      expect(result.current, 2);
      expect(result.total, 3);
    });

    test('Fajr rakaat 1: orderIndex 1 returns 1/2', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2)],
        ),
      ];
      final result = StageStepScreenFlowHelper.displayStepProgressFor(
        rakaats: rakaats,
        prayerCode: 'fajr',
        rakaatIndex: 0,
        stepIndex: 0,
        stepOrderIndexesForRakaatIndex: (_) => const [1, 2],
      );
      expect(result.current, 1);
      expect(result.total, 2);
    });

    test('Fajr rakaat 1: orderIndex 2 returns 2/2', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2)],
        ),
      ];
      final result = StageStepScreenFlowHelper.displayStepProgressFor(
        rakaats: rakaats,
        prayerCode: 'fajr',
        rakaatIndex: 0,
        stepIndex: 1,
        stepOrderIndexesForRakaatIndex: (_) => const [1, 2],
      );
      expect(result.current, 2);
      expect(result.total, 2);
    });

    test('Fajr rakaat 1: orderIndex >2 collapses into 14-step group', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [
            for (var i = 1; i <= 5; i++) _step(orderIndex: i),
          ],
        ),
      ];
      final result = StageStepScreenFlowHelper.displayStepProgressFor(
        rakaats: rakaats,
        prayerCode: 'fajr',
        rakaatIndex: 0,
        stepIndex: 2,
        stepOrderIndexesForRakaatIndex: (_) => const [1, 2, 3, 4, 5],
      );
      expect(result.current, 1);
      expect(result.total, 14);
    });

    test('Fajr rakaat 2 uses default (non-Fajr) progression', () {
      final rakaats = [
        _rakaat(number: 1, steps: [_step(orderIndex: 1)]),
        _rakaat(
          number: 2,
          steps: [_step(orderIndex: 1), _step(orderIndex: 2)],
        ),
      ];
      final result = StageStepScreenFlowHelper.displayStepProgressFor(
        rakaats: rakaats,
        prayerCode: 'fajr',
        rakaatIndex: 1,
        stepIndex: 0,
        stepOrderIndexesForRakaatIndex: (_) => const [1, 2],
      );
      expect(result.current, 1);
      expect(result.total, 2);
    });
  });

  group('StageStepScreenFlowHelper.groupedStepsForRakaat', () {
    test('returns empty for empty rakaats', () {
      expect(
        StageStepScreenFlowHelper.groupedStepsForRakaat(
          rakaats: const [],
          rakaatIndex: 0,
        ),
        isEmpty,
      );
    });

    test('groups by orderIndex sorted ascending, dedupes by first occurrence', () {
      final rakaats = [
        _rakaat(
          number: 1,
          steps: [
            _step(orderIndex: 3, title: 'C'),
            _step(orderIndex: 1, title: 'A'),
            _step(orderIndex: 1, title: 'A2'),
            _step(orderIndex: 2, title: 'B'),
          ],
        ),
      ];
      final groups = StageStepScreenFlowHelper.groupedStepsForRakaat(
        rakaats: rakaats,
        rakaatIndex: 0,
      );
      expect(groups.map((g) => g.title), ['A', 'B', 'C']);
    });

    test('clamps rakaatIndex out of range', () {
      final rakaats = [
        _rakaat(number: 1, steps: [_step(orderIndex: 1, title: 'X')]),
      ];
      final groups = StageStepScreenFlowHelper.groupedStepsForRakaat(
        rakaats: rakaats,
        rakaatIndex: 99,
      );
      expect(groups.length, 1);
      expect(groups.first.title, 'X');
    });
  });
}
