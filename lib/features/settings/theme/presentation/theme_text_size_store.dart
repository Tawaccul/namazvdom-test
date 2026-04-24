class ThemeTextSizeStore {
  ThemeTextSizeStore._();

  static const List<double> _snapPoints = <double>[0.0, 0.5, 1.0];
  static const List<double> _textSizes = <double>[14.0, 16.0, 18.0];

  static double _normalized = 0.5;

  static double get normalized => _normalized;

  static double get scale => scaleFor(_normalized);

  static double get textSize => textSizeFor(_normalized);

  static String get label => labelFor(_normalized);

  static void setNormalized(double value) {
    _normalized = snapNormalized(value);
  }

  static double snapNormalized(double value) {
    final clamped = value.clamp(0.0, 1.0);
    var best = _snapPoints.first;
    var minDelta = (best - clamped).abs();
    for (final point in _snapPoints.skip(1)) {
      final delta = (point - clamped).abs();
      if (delta < minDelta) {
        minDelta = delta;
        best = point;
      }
    }
    return best;
  }

  static int indexFor(double normalized) {
    final snapped = snapNormalized(normalized);
    return _snapPoints.indexOf(snapped);
  }

  static double textSizeFor(double normalized) {
    return _textSizes[indexFor(normalized)];
  }

  static double scaleFor(double normalized) {
    return textSizeFor(normalized) / 16.0;
  }

  static String labelFor(double normalized) {
    return switch (indexFor(normalized)) {
      0 => 'Small',
      1 => 'Standard',
      _ => 'Large',
    };
  }
}
