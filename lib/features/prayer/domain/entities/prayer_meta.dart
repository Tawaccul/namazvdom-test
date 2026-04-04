import 'package:flutter/foundation.dart';

@immutable
class PrayerMeta {
  const PrayerMeta({
    required this.lastModifiedAt,
    required this.scope,
    required this.eTag,
  });

  final DateTime? lastModifiedAt;
  final String scope;
  final String? eTag;
}
