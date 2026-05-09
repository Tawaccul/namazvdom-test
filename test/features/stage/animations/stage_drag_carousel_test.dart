import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayday/features/stage/animations/stage_drag_carousel.dart';

void main() {
  testWidgets('programmatic next animates the real next child into view', (
    tester,
  ) async {
    final controller = StageDragCarouselController();

    await tester.pumpWidget(
      MaterialApp(home: _CarouselHost(controller: controller)),
    );

    expect(find.text('current-0'), findsOneWidget);
    expect(find.text('next-1'), findsOneWidget);
    final restingDx = tester.getCenter(find.text('current-0')).dx;

    final animation = controller.animateNext();
    await tester.pump();

    expect(find.text('current-1'), findsOneWidget);
    expect(find.text('prev-0'), findsOneWidget);
    expect(find.text('current-0'), findsNothing);
    final startDx = tester.getCenter(find.text('current-1')).dx;
    expect(startDx, greaterThan(restingDx + 300));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    final midDx = tester.getCenter(find.text('current-1')).dx;
    expect(midDx, lessThan(startDx));
    expect(midDx, greaterThan(restingDx));

    await tester.pumpAndSettle();
    await animation;
    expect(tester.getCenter(find.text('current-1')).dx, closeTo(restingDx, 1));
  });

  testWidgets('programmatic prev animates the real previous child into view', (
    tester,
  ) async {
    final controller = StageDragCarouselController();

    await tester.pumpWidget(
      MaterialApp(home: _CarouselHost(controller: controller, initialIndex: 1)),
    );

    expect(find.text('current-1'), findsOneWidget);
    expect(find.text('prev-0'), findsOneWidget);
    final restingDx = tester.getCenter(find.text('current-1')).dx;

    final animation = controller.animatePrev();
    await tester.pump();

    expect(find.text('current-0'), findsOneWidget);
    expect(find.text('next-1'), findsOneWidget);
    expect(find.text('current-1'), findsNothing);
    final startDx = tester.getCenter(find.text('current-0')).dx;
    expect(startDx, lessThan(restingDx - 300));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    final midDx = tester.getCenter(find.text('current-0')).dx;
    expect(midDx, greaterThan(startDx));
    expect(midDx, lessThan(restingDx));

    await tester.pumpAndSettle();
    await animation;
    expect(tester.getCenter(find.text('current-0')).dx, closeTo(restingDx, 1));
  });

  testWidgets('allows tall ghost content without flex overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 120,
          child: StageDragCarousel(
            canGoPrev: false,
            canGoNext: true,
            onPrev: () async {},
            onNext: () async {},
            childBuilder: (context, dragProgress) =>
                const SizedBox(height: 120, child: Text('current')),
            prevGhost: null,
            nextGhost: Column(
              children: List.generate(
                30,
                (index) => SizedBox(height: 80, child: Text('ghost-$index')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

class _CarouselHost extends StatefulWidget {
  const _CarouselHost({required this.controller, this.initialIndex = 0});

  final StageDragCarouselController controller;
  final int initialIndex;

  @override
  State<_CarouselHost> createState() => _CarouselHostState();
}

class _CarouselHostState extends State<_CarouselHost> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 120,
      child: StageDragCarousel(
        controller: widget.controller,
        canGoPrev: _index > 0,
        canGoNext: _index < 2,
        onPrev: _goPrev,
        onNext: _goNext,
        onProgrammaticPrev: _goPrev,
        onProgrammaticNext: _goNext,
        childBuilder: (context, dragProgress) =>
            Center(child: Text('current-$_index')),
        prevGhost: _index > 0
            ? Center(child: Text('prev-${_index - 1}'))
            : null,
        nextGhost: _index < 2
            ? Center(child: Text('next-${_index + 1}'))
            : null,
      ),
    );
  }

  Future<void> _goNext() async {
    setState(() => _index += 1);
  }

  Future<void> _goPrev() async {
    setState(() => _index -= 1);
  }
}
