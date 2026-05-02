class AblutionManifest {
  const AblutionManifest({
    required this.titleKey,
    required this.descriptionKey,
    required this.steps,
  });

  factory AblutionManifest.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];
    return AblutionManifest(
      titleKey: json['title_key'] as String? ?? 'ablution.title',
      descriptionKey: json['description_key'] as String? ?? '',
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(AblutionStepManifest.fromJson)
          .toList(growable: false),
    );
  }

  final String titleKey;
  final String descriptionKey;
  final List<AblutionStepManifest> steps;
}

class AblutionStepManifest {
  const AblutionStepManifest({
    required this.id,
    required this.image,
    required this.audio,
    required this.titleKey,
    required this.descriptionKey,
    this.text,
  });

  factory AblutionStepManifest.fromJson(Map<String, dynamic> json) {
    return AblutionStepManifest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      image: json['image'] as String? ?? '',
      audio: json['audio'] as String? ?? '',
      titleKey: json['title_key'] as String? ?? '',
      descriptionKey: json['description_key'] as String? ?? '',
      text: AblutionStepTextManifest.fromJson(
        json['text'] as Map<String, dynamic>?,
      ),
    );
  }

  final int id;
  final String image;
  final String audio;
  final String titleKey;
  final String descriptionKey;
  final AblutionStepTextManifest? text;
}

class AblutionStepTextManifest {
  const AblutionStepTextManifest({
    required this.arabic,
    required this.transliteration,
    required this.translationKey,
  });

  static AblutionStepTextManifest? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AblutionStepTextManifest(
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translationKey: json['translation_key'] as String? ?? '',
    );
  }

  final String arabic;
  final String transliteration;
  final String translationKey;
}

class AblutionOverviewPageReference {
  const AblutionOverviewPageReference({required this.stepIndex});

  final int stepIndex;
}
