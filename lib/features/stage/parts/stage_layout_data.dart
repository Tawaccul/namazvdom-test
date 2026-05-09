import 'package:flutter/widgets.dart';

class StageLayoutData extends InheritedWidget {
  const StageLayoutData({
    super.key,
    required this.topInset,
    required this.bottomInset,
    required this.cardTextSize,
    required super.child,
  });

  final double topInset;
  final double bottomInset;
  final double cardTextSize;

  static StageLayoutData of(BuildContext context) {
    final data = context.dependOnInheritedWidgetOfExactType<StageLayoutData>();
    assert(data != null, 'StageLayoutData not found in widget tree');
    return data!;
  }

  @override
  bool updateShouldNotify(StageLayoutData old) =>
      topInset != old.topInset ||
      bottomInset != old.bottomInset ||
      cardTextSize != old.cardTextSize;
}
