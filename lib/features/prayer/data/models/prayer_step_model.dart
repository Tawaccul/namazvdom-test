import '../../domain/entities/prayer_step.dart';

class PrayerStepContentModel {
  PrayerStepContentModel({
    required this.movementDescription,
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  final String movementDescription;
  final String recitationArabic;
  final String translation;
  final String transliteration;

  PrayerStepContent toEntity() => PrayerStepContent(
    movementDescription: movementDescription,
    recitationArabic: recitationArabic,
    translation: translation,
    transliteration: transliteration,
  );
}

class PrayerStepRecitationModel {
  PrayerStepRecitationModel({
    required this.recitationArabic,
    required this.translation,
    required this.transliteration,
  });

  factory PrayerStepRecitationModel.fromJson(Map<String, dynamic> json) {
    return PrayerStepRecitationModel(
      recitationArabic: (json['recitationArabic'] as String?)?.trim() ?? '',
      translation: (json['translation'] as String?)?.trim() ?? '',
      transliteration: (json['transliteration'] as String?)?.trim() ?? '',
    );
  }

  final String recitationArabic;
  final String translation;
  final String transliteration;

  Map<String, dynamic> toJson() => {
    'recitationArabic': recitationArabic,
    'translation': translation,
    'transliteration': transliteration,
  };

  PrayerStepRecitation toEntity() => PrayerStepRecitation(
    recitationArabic: recitationArabic,
    translation: translation,
    transliteration: transliteration,
  );
}

class PrayerStepSurahContentModel {
  PrayerStepSurahContentModel({
    required this.code,
    required this.name,
    required this.recitations,
  });

  factory PrayerStepSurahContentModel.fromJson(Map<String, dynamic> json) {
    final recs = (json['recitations'] as List?)?.cast<dynamic>() ?? const [];
    return PrayerStepSurahContentModel(
      code: (json['code'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      recitations: recs
          .whereType<Map>()
          .map((e) => PrayerStepRecitationModel.fromJson(
                e.cast<String, dynamic>(),
              ))
          .toList(growable: false),
    );
  }

  final String code;
  final String name;
  final List<PrayerStepRecitationModel> recitations;

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'recitations': recitations.map((e) => e.toJson()).toList(),
  };

  PrayerStepSurahContent toEntity() => PrayerStepSurahContent(
    code: code,
    name: name,
    recitations: recitations.map((e) => e.toEntity()).toList(growable: false),
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
    required this.movementDescription,
    required this.recitations,
    required this.surahs,
    required this.surahCode,
    required this.availableSurahs,
  });

  /// Parses both the live server schema (`movement` / `recitations` / `duas`)
  /// and our own cached shape (`movementDescription` + flattened
  /// `recitations`). Detection is by the presence of the server-only
  /// `movement` object or `duas` array.
  factory PrayerStepModel.fromJson(Map<String, dynamic> json) {
    final isServerShape = json['movement'] is Map || json['duas'] is List;

    final String movementDescription;
    final List<PrayerStepRecitationModel> recitations;

    if (isServerShape) {
      final movement = (json['movement'] as Map?)?.cast<String, dynamic>();
      movementDescription = (movement?['description'] as String?)?.trim() ?? '';
      recitations = _flattenServerRecitations(json);
    } else {
      // Cached shape written by [toJson], or a legacy `content` object.
      final content = (json['content'] as Map?)?.cast<String, dynamic>();
      movementDescription =
          (json['movementDescription'] as String?)?.trim() ??
          (content?['movementDescription'] as String?)?.trim() ??
          '';
      final rawRecitations = (json['recitations'] as List?)?.cast<dynamic>();
      if (rawRecitations != null) {
        recitations = rawRecitations
            .whereType<Map>()
            .map((e) => PrayerStepRecitationModel.fromJson(
                  e.cast<String, dynamic>(),
                ))
            .toList(growable: false);
      } else if (content != null) {
        recitations = [PrayerStepRecitationModel.fromJson(content)]
            .where((r) =>
                r.recitationArabic.isNotEmpty ||
                r.translation.isNotEmpty ||
                r.transliteration.isNotEmpty)
            .toList(growable: false);
      } else {
        recitations = const [];
      }
    }

    final surahs = ((json['surahs'] as List?)?.cast<dynamic>() ?? const [])
        .whereType<Map>()
        .map(
          (e) => PrayerStepSurahContentModel.fromJson(e.cast<String, dynamic>()),
        )
        .where((s) => s.code.isNotEmpty)
        .toList(growable: false);

    return PrayerStepModel(
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      stepCode: (json['stepCode'] as String?) ?? '',
      recitationMode: (json['recitationMode'] as String?) ?? '',
      hasRecitation: (json['hasRecitation'] as bool?) ?? false,
      movementDescription: movementDescription,
      recitations: recitations,
      surahs: surahs,
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

  /// Builds the display recitation list. The richest content lives in `duas`
  /// (split into parts, with transliteration), so when a step has duas we use
  /// them; otherwise we fall back to the step's own `recitations`.
  static List<PrayerStepRecitationModel> _flattenServerRecitations(
    Map<String, dynamic> json,
  ) {
    List<PrayerStepRecitationModel> parse(List<dynamic> raw) => raw
        .whereType<Map>()
        .map((e) => PrayerStepRecitationModel.fromJson(e.cast<String, dynamic>()))
        .where((r) =>
            r.recitationArabic.isNotEmpty ||
            r.translation.isNotEmpty ||
            r.transliteration.isNotEmpty)
        .toList();

    final duas = (json['duas'] as List?)?.cast<dynamic>() ?? const [];
    if (duas.isNotEmpty) {
      final out = <PrayerStepRecitationModel>[];
      for (final dua in duas.whereType<Map>()) {
        final duaJson = dua.cast<String, dynamic>();
        final recs = (duaJson['recitations'] as List?)?.cast<dynamic>();
        if (recs != null) out.addAll(parse(recs));
      }
      if (out.isNotEmpty) return out;
    }

    final recs = (json['recitations'] as List?)?.cast<dynamic>() ?? const [];
    return parse(recs);
  }

  final int orderIndex;
  final String stepCode;
  final String recitationMode;
  final bool hasRecitation;
  final String movementDescription;
  final List<PrayerStepRecitationModel> recitations;
  final List<PrayerStepSurahContentModel> surahs;
  final String? surahCode;
  final List<PrayerStepSurahOptionModel> availableSurahs;

  PrayerStepContentModel get _content {
    final first = recitations.isNotEmpty ? recitations.first : null;
    return PrayerStepContentModel(
      movementDescription: movementDescription,
      recitationArabic: first?.recitationArabic ?? '',
      translation: first?.translation ?? '',
      transliteration: first?.transliteration ?? '',
    );
  }

  /// Stable shape consumed back by [fromJson] (cached-shape branch). Must not
  /// emit `movement`/`duas` so the cache round-trips deterministically.
  Map<String, dynamic> toJson() => {
    'orderIndex': orderIndex,
    'stepCode': stepCode,
    'recitationMode': recitationMode,
    'hasRecitation': hasRecitation,
    'movementDescription': movementDescription,
    'recitations': recitations.map((e) => e.toJson()).toList(),
    'surahs': surahs.map((e) => e.toJson()).toList(),
    'surahCode': surahCode,
    'availableSurahs': availableSurahs.map((item) => item.toJson()).toList(),
  };

  PrayerStep toEntity() => PrayerStep(
    orderIndex: orderIndex,
    stepCode: stepCode,
    recitationMode: recitationMode,
    hasRecitation: hasRecitation,
    content: _content.toEntity(),
    recitations: recitations.map((e) => e.toEntity()).toList(growable: false),
    surahs: surahs.map((e) => e.toEntity()).toList(growable: false),
    surahCode: surahCode,
    availableSurahs: availableSurahs
        .map((item) => item.toEntity())
        .toList(growable: false),
  );
}
