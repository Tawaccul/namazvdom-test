import '../../domain/entities/prayer_step.dart';

class PrayerStepContentModel {
  PrayerStepContentModel({
    required this.movementDescription,
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  factory PrayerStepContentModel.fromJson(Map<String, dynamic> json) {
    return PrayerStepContentModel(
      movementDescription: (json['movementDescription'] as String?) ?? '',
      recitationArabic: (json['recitationArabic'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      transliteration: (json['transliteration'] as String?) ?? '',
    );
  }

  final String movementDescription;
  final String recitationArabic;
  final String translation;
  final String transliteration;

  Map<String, dynamic> toJson() => {
    'movementDescription': movementDescription,
    'recitationArabic': recitationArabic,
    'translation': translation,
    'transliteration': transliteration,
  };

  PrayerStepContent toEntity() => PrayerStepContent(
    movementDescription: movementDescription,
    recitationArabic: recitationArabic,
    translation: translation,
    transliteration: transliteration,
  );
}

class PrayerStepSurahOptionModel {
  PrayerStepSurahOptionModel({required this.code, required this.name});

  factory PrayerStepSurahOptionModel.fromJson(Map<String, dynamic> json) {
    return PrayerStepSurahOptionModel(
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  final String code;
  final String name;

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  PrayerStepSurahOption toEntity() =>
      PrayerStepSurahOption(code: code, name: name);
}

class PrayerStepModel {
  PrayerStepModel({
    required this.orderIndex,
    required this.stepCode,
    required this.recitationMode,
    required this.hasRecitation,
    required this.content,
    required this.surahCode,
    required this.availableSurahs,
  });

  factory PrayerStepModel.fromJson(Map<String, dynamic> json) {
    return PrayerStepModel(
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      stepCode: (json['stepCode'] as String?) ?? '',
      recitationMode: (json['recitationMode'] as String?) ?? '',
      hasRecitation: (json['hasRecitation'] as bool?) ?? false,
      content: PrayerStepContentModel.fromJson(
        (json['content'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      surahCode: (json['surahCode'] as String?)?.trim(),
      availableSurahs:
          ((json['availableSurahs'] as List?)?.cast<dynamic>() ?? const [])
              .whereType<Map>()
              .map(
                (item) => PrayerStepSurahOptionModel.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .where((item) => item.code.trim().isNotEmpty)
              .toList(growable: false),
    );
  }

  final int orderIndex;
  final String stepCode;
  final String recitationMode;
  final bool hasRecitation;
  final PrayerStepContentModel content;
  final String? surahCode;
  final List<PrayerStepSurahOptionModel> availableSurahs;

  Map<String, dynamic> toJson() => {
    'orderIndex': orderIndex,
    'stepCode': stepCode,
    'recitationMode': recitationMode,
    'hasRecitation': hasRecitation,
    'content': content.toJson(),
    'surahCode': surahCode,
    'availableSurahs': availableSurahs.map((item) => item.toJson()).toList(),
  };

  PrayerStep toEntity() => PrayerStep(
    orderIndex: orderIndex,
    stepCode: stepCode,
    recitationMode: recitationMode,
    hasRecitation: hasRecitation,
    content: content.toEntity(),
    surahCode: surahCode,
    availableSurahs: availableSurahs
        .map((item) => item.toEntity())
        .toList(growable: false),
  );
}
