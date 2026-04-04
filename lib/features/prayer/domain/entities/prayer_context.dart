import 'package:flutter/foundation.dart';

import 'prayer_request_context.dart';

@immutable
class PrayerContext {
  const PrayerContext({
    required this.prayerCode,
    required this.madhhabCode,
    required this.genderCode,
    required this.languageCode,
    required this.rakah,
    required this.script,
    required this.totalRakahCount,
  });

  factory PrayerContext.fromRequest(
    PrayerRequestContext request, {
    required int totalRakahCount,
  }) {
    return PrayerContext(
      prayerCode: request.prayerCode ?? '',
      madhhabCode: request.madhhabCode ?? '',
      genderCode: request.genderCode ?? '',
      languageCode: request.languageCode ?? '',
      rakah: request.rakah ?? 1,
      script: request.script ?? '',
      totalRakahCount: totalRakahCount,
    );
  }

  final String prayerCode;
  final String madhhabCode;
  final String genderCode;
  final String languageCode;
  final int rakah;
  final String script;
  final int totalRakahCount;
}
