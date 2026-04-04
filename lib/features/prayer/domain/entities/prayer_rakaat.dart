import 'package:flutter/foundation.dart';

import 'prayer_context.dart';
import 'prayer_meta.dart';
import 'prayer_step.dart';

@immutable
class PrayerRakaat {
  const PrayerRakaat({
    required this.context,
    required this.steps,
    required this.meta,
  });

  final PrayerContext context;
  final List<PrayerStep> steps;
  final PrayerMeta meta;
}
