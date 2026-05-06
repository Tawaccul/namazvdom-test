import '../models/rakaat_models.dart';

/// Данные соседнего шага намаза, нужные для отрисовки ghost-карточки
/// в карусели.
class StageNeighborStepBundle {
  const StageNeighborStepBundle({
    required this.stepTitle,
    required this.movementDescription,
    required this.stepImageAsset,
    required this.fallbackStepImageAsset,
    required this.entries,
  });

  final String stepTitle;
  final String movementDescription;
  final String stepImageAsset;
  final String fallbackStepImageAsset;
  final List<RakaatStep> entries;
}
