import '../../domain/entities/prayer_context.dart';

class PrayerContextModel {
  PrayerContextModel({
    required this.prayerCode,
    required this.madhhabCode,
    required this.genderCode,
    required this.languageCode,
    required this.rakah,
    required this.script,
    required this.totalRakahCount,
  });

  factory PrayerContextModel.fromJson(Map<String, dynamic> json) {
    return PrayerContextModel(
      prayerCode: (json['prayerCode'] as String?) ?? '',
      madhhabCode: (json['madhhabCode'] as String?) ?? '',
      genderCode: (json['genderCode'] as String?) ?? '',
      languageCode: (json['languageCode'] as String?) ?? '',
      rakah: (json['rakah'] as num?)?.toInt() ?? 1,
      script: (json['script'] as String?) ?? '',
      totalRakahCount: (json['totalRakahCount'] as num?)?.toInt() ?? 1,
    );
  }

  final String prayerCode;
  final String madhhabCode;
  final String genderCode;
  final String languageCode;
  final int rakah;
  final String script;
  final int totalRakahCount;

  Map<String, dynamic> toJson() => {
    'prayerCode': prayerCode,
    'madhhabCode': madhhabCode,
    'genderCode': genderCode,
    'languageCode': languageCode,
    'rakah': rakah,
    'script': script,
    'totalRakahCount': totalRakahCount,
  };

  PrayerContext toEntity() => PrayerContext(
    prayerCode: prayerCode,
    madhhabCode: madhhabCode,
    genderCode: genderCode,
    languageCode: languageCode,
    rakah: rakah,
    script: script,
    totalRakahCount: totalRakahCount,
  );
}
