import '../../domain/entities/prayer_meta.dart';

class PrayerMetaModel {
  PrayerMetaModel({
    required this.lastModifiedAt,
    required this.scope,
    required this.eTag,
  });

  factory PrayerMetaModel.fromEntity(PrayerMeta meta) {
    return PrayerMetaModel(
      lastModifiedAt: meta.lastModifiedAt,
      scope: meta.scope,
      eTag: meta.eTag,
    );
  }

  factory PrayerMetaModel.fromJson(Map<String, dynamic> json) {
    final raw = json['lastModifiedAt'];
    final lastModifiedAt = raw is String ? DateTime.tryParse(raw) : null;
    return PrayerMetaModel(
      lastModifiedAt: lastModifiedAt,
      scope: (json['scope'] as String?) ?? 'global',
      eTag: (json['eTag'] as String?) ?? (json['etag'] as String?),
    );
  }

  final DateTime? lastModifiedAt;
  final String scope;
  final String? eTag;

  Map<String, dynamic> toJson() => {
    'lastModifiedAt': lastModifiedAt?.toUtc().toIso8601String(),
    'scope': scope,
    'eTag': eTag,
  };

  PrayerMeta toEntity() =>
      PrayerMeta(lastModifiedAt: lastModifiedAt, scope: scope, eTag: eTag);
}
