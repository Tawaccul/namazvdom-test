import 'package:flutter/foundation.dart';

@immutable
class PrayerRequestContext {
  const PrayerRequestContext({
    this.prayerCode,
    this.madhhabCode,
    this.genderCode,
    this.languageCode,
    this.rakah,
    this.script,
  });

  final String? prayerCode;
  final String? madhhabCode;
  final String? genderCode;
  final String? languageCode;
  final int? rakah;
  final String? script;

  PrayerRequestContext copyWith({
    String? prayerCode,
    String? madhhabCode,
    String? genderCode,
    String? languageCode,
    int? rakah,
    String? script,
  }) {
    return PrayerRequestContext(
      prayerCode: prayerCode ?? this.prayerCode,
      madhhabCode: madhhabCode ?? this.madhhabCode,
      genderCode: genderCode ?? this.genderCode,
      languageCode: languageCode ?? this.languageCode,
      rakah: rakah ?? this.rakah,
      script: script ?? this.script,
    );
  }

  String get scopeKey {
    final p = prayerCode ?? '';
    final m = madhhabCode ?? '';
    final g = genderCode ?? '';
    final l = languageCode ?? '';
    final s = script ?? '';
    return '$p|$m|$g|$l|$s';
  }

  String get cacheKey {
    final r = rakah?.toString() ?? '';
    return '$scopeKey|rakah=$r';
  }
}
