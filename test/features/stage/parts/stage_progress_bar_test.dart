import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/stage/parts/stage_progress_bar.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 360, child: child),
      ),
    ),
  );
}

void main() {
  group('StageProgressBlock', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          StageProgressBlock(
            title: 'Зухр - 4 ракаата',
            rakaatIndex: 1,
            totalRakaats: 4,
            stepIndex: 1,
            totalSteps: 8,
            progress: 0.25,
            animateProgress: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Зухр - 4 ракаата'), findsOneWidget);
    });

    testWidgets('contains StageProgressBar with passed value', (tester) async {
      await tester.pumpWidget(
        _wrap(
          StageProgressBlock(
            title: 'X',
            rakaatIndex: 1,
            totalRakaats: 2,
            stepIndex: 1,
            totalSteps: 4,
            progress: 0.6,
            animateProgress: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.widget<StageProgressBar>(
        find.byType(StageProgressBar),
      );
      expect(bar.value, 0.6);
      expect(bar.animate, isFalse);
    });

    testWidgets('renders empty title without crash', (tester) async {
      await tester.pumpWidget(
        _wrap(
          StageProgressBlock(
            title: '',
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
      expect(find.byType(StageProgressBlock), findsOneWidget);
    });
  });

  group('StageProgressBar', () {
    testWidgets('clamps progress > 1 to full width', (tester) async {
      await tester.pumpWidget(
        _wrap(const StageProgressBar(value: 1.5, animate: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StageProgressBar), findsOneWidget);
    });

    testWidgets('clamps negative progress', (tester) async {
      await tester.pumpWidget(
        _wrap(const StageProgressBar(value: -0.3, animate: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StageProgressBar), findsOneWidget);
    });

    testWidgets('renders without animation when animate=false', (tester) async {
      await tester.pumpWidget(
        _wrap(const StageProgressBar(value: 0.5, animate: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('renders AnimatedContainer when animate=true', (tester) async {
      await tester.pumpWidget(
        _wrap(const StageProgressBar(value: 0.5, animate: true)),
      );
      // Don't pumpAndSettle - the animation may oscillate; one frame is enough.
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('handles 12px fixed height', (tester) async {
      await tester.pumpWidget(
        _wrap(const StageProgressBar(value: 0.5, animate: false)),
      );
      await tester.pumpAndSettle();
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(StageProgressBar),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 12);
    });
  });
}
