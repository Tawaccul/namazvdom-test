import '../../domain/entities/prayer_rakaat.dart';
import 'prayer_context_model.dart';
import 'prayer_meta_model.dart';
import 'prayer_step_model.dart';

class PrayerRakaatResponseModel {
  PrayerRakaatResponseModel({
    required this.context,
    required this.steps,
    required this.meta,
  });

  factory PrayerRakaatResponseModel.fromJson(Map<String, dynamic> json) {
    final metaJson =
        (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final dataJson =
        (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final ctxJson =
        (dataJson['context'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stepsJson = (dataJson['steps'] as List?)?.cast<dynamic>() ?? const [];
    return PrayerRakaatResponseModel(
      context: PrayerContextModel.fromJson(ctxJson),
      steps: stepsJson
          .whereType<Map>()
          .map((e) => PrayerStepModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
      meta: PrayerMetaModel.fromJson(metaJson),
    );
  }

  final PrayerContextModel context;
  final List<PrayerStepModel> steps;
  final PrayerMetaModel meta;

  Map<String, dynamic> toJson() => {
    'data': {
      'context': context.toJson(),
      'steps': steps.map((e) => e.toJson()).toList(),
    },
    'meta': meta.toJson(),
  };

  PrayerRakaat toEntity() => PrayerRakaat(
    context: context.toEntity(),
    steps: steps.map((e) => e.toEntity()).toList(),
    meta: meta.toEntity(),
  );
}
