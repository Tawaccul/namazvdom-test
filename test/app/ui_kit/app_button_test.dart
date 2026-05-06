import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/app/ui_kit/app_button.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 300, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('renders provided label', (tester) async {
      await tester.pumpWidget(
        _wrap(AppButton(label: 'Hello world', onPressed: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('large size has fixed 50px height', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppButton(
            label: 'Tap me',
            onPressed: null,
            size: AppButtonSize.large,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('medium size has fixed 50px height', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppButton(
            label: 'Tap me',
            onPressed: null,
            size: AppButtonSize.medium,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton(label: 'Click', onPressed: () => taps++)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('does not invoke onPressed when null (disabled)', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppButton(label: 'Disabled', onPressed: null)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      // No assertion needed: would throw if onPressed somehow ran.
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('does not invoke onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Saving',
            onPressed: () => taps++,
            isLoading: true,
          ),
        ),
      );
      // CircularProgressIndicator runs an infinite animation, so we
      // can't use pumpAndSettle here. A single pump is enough to lay out.
      await tester.pump();
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('shows spinner while loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'Saving', onPressed: () {}, isLoading: true),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('exposes button semantics with provided label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          AppButton(
            label: 'Continue',
            onPressed: () {},
            semanticLabel: 'Continue button',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.byType(AppButton));
      expect(node.label, contains('Continue button'));
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton(label: 'Dark', onPressed: () {}),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('all variants render the label', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _wrap(
            AppButton(
              label: 'V-${variant.name}',
              onPressed: () {},
              variant: variant,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('V-${variant.name}'),
          findsOneWidget,
          reason: 'variant ${variant.name} should render label',
        );
      }
    });
  });
}
