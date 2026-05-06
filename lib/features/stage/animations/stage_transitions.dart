import 'stage_carousel_transition.dart';
import 'stage_cube_transition.dart';
import 'stage_fade_zoom_transition.dart';
import 'stage_parallax_transition.dart';
import 'stage_stacked_transition.dart';
import 'stage_transition.dart';

/// Реестр всех доступных анимаций перехода между шагами.
const List<StageStepTransition> stageStepTransitions = [
  StageCarouselTransition(),
  StageParallaxTransition(),
  StageStackedTransition(),
  StageCubeTransition(),
  StageFadeZoomTransition(),
];

/// Текущая выбранная анимация. Меняй индекс чтобы протестировать
/// разные варианты, либо подключи к UI настроек.
StageStepTransition activeStageStepTransition = stageStepTransitions[0];
