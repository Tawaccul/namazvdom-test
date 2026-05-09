import 'package:flutter/widgets.dart';

class AblutionLayoutData extends InheritedWidget {
  const AblutionLayoutData({
    super.key,
    required this.topInset,
    required this.bottomInset,
    required this.cardTextSize,
    required super.child,
  });

  final double topInset;
  final double bottomInset;
  final double cardTextSize;

  static AblutionLayoutData of(BuildContext context) {
    final data =
        context.dependOnInheritedWidgetOfExactType<AblutionLayoutData>();
    assert(data != null, 'AblutionLayoutData not found in widget tree');
    return data!;
  }

  @override
  bool updateShouldNotify(AblutionLayoutData old) =>
      topInset != old.topInset ||
      bottomInset != old.bottomInset ||
      cardTextSize != old.cardTextSize;
}
