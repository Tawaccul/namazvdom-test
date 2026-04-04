class RakaatStep {
  const RakaatStep({
    required this.orderIndex,
    required this.title,
    required this.movementDescription,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.stepCode,
    this.audioUrl = '',
    this.surahCode = '',
    this.additionalSurahOptionCode = '',
  });

  final int orderIndex;
  final String title;
  final String movementDescription;
  final String arabic;
  final String transliteration;
  final String translation;
  final String stepCode;
  final String audioUrl;
  final String surahCode;
  final String additionalSurahOptionCode;

  bool get hasAudio => audioUrl.isNotEmpty;
}

class RakaatSurahOption {
  const RakaatSurahOption({required this.code, required this.label});

  final String code;
  final String label;
}

class RakaatData {
  const RakaatData({
    required this.number,
    required this.imageAsset,
    required this.steps,
    this.additionalSurahOptions = const [],
  });

  final int number;
  final String imageAsset;
  final List<RakaatStep> steps;
  final List<RakaatSurahOption> additionalSurahOptions;
}
