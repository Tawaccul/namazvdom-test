import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/stage/parts/stage_pinned_progress.dart';
import 'package:prayday/features/stage/parts/stage_progress_bar.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: SizedBox(width: 360, child: child),
      ),
    ),
  );
}

void main() {
  group('StagePinnedProgressCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StagePinnedProgressCard(
            rakaatIndex: 1,
            totalRakaats: 4,
            stepIndex: 2,
            totalSteps: 6,
            progress: 0.33,
            animateProgress: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StagePinnedProgressCard), findsOneWidget);
    });

    testWidgets('contains StageProgressBar with the passed progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StagePinnedProgressCard(
            rakaatIndex: 0,
            totalRakaats: 2,
            stepIndex: 0,
            totalSteps: 4,
            progress: 0.75,
            animateProgress: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.widget<StageProgressBar>(
        find.byType(StageProgressBar),
      );
      expect(bar.value, 0.75);
      expect(bar.animate, isFalse);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StagePinnedProgressCard(
            rakaatIndex: 1,
            totalRakaats: 4,
            stepIndex: 2,
            totalSteps: 6,
            progress: 0.5,
            animateProgress: false,
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StagePinnedProgressCard), findsOneWidget);
    });

    testWidgets('handles zero totalRakaats / totalSteps without crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StagePinnedProgressCard(
            rakaatIndex: 0,
            totalRakaats: 0,
            stepIndex: 0,
            totalSteps: 0,
            progress: 0,
            animateProgress: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StagePinnedProgressCard), findsOneWidget);
    });

    testWidgets('handles full progress (1.0) without crash', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StagePinnedProgressCard(
            rakaatIndex: 4,
            totalRakaats: 4,
            stepIndex: 6,
            totalSteps: 6,
            progress: 1.0,
            animateProgress: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StagePinnedProgressCard), findsOneWidget);
    });
  });
}
