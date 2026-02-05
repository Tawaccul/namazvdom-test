class RakaatStep {
  const RakaatStep({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.audioUrl = '',
  });

  final String arabic;
  final String transliteration;
  final String translation;
  final String audioUrl;

  bool get hasAudio => audioUrl.isNotEmpty;
}

class RakaatData {
  const RakaatData({
    required this.number,
    required this.imageAsset,
    required this.steps,
  });

  final int number;
  final String imageAsset;
  final List<RakaatStep> steps;
}
