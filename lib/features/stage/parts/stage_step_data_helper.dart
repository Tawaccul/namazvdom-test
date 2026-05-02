import '../models/rakaat_models.dart';
import '../models/stage_step_screen_models.dart';

class StageStepDataHelper {
  static int stepCountForRakaat({
    required List<RakaatData> rakaats,
    required int rakaatIndex,
  }) {
    if (rakaats.isEmpty) return 0;
    final index = rakaatIndex.clamp(0, rakaats.length - 1);
    final set = <int>{};
    for (final step in rakaats[index].steps) {
      set.add(step.orderIndex);
    }
    return set.length;
  }

  static List<int> stepOrderIndexesForRakaatIndex({
    required List<RakaatData> rakaats,
    required int rakaatIndex,
  }) {
    if (rakaats.isEmpty) return const [];
    final normalized = rakaatIndex.clamp(0, rakaats.length - 1);
    final set = <int>{};
    for (final step in rakaats[normalized].steps) {
      set.add(step.orderIndex);
    }
    final indexes = set.toList()..sort();
    return indexes;
  }

  static List<int> currentStepOrderIndexes({
    required List<RakaatStep> currentRakaatSteps,
  }) {
    final set = <int>{};
    for (final step in currentRakaatSteps) {
      set.add(step.orderIndex);
    }
    final indexes = set.toList()..sort();
    return indexes;
  }

  static List<RakaatStep> currentStepEntries({
    required List<RakaatStep> currentRakaatSteps,
    required int? currentStepOrderIndex,
  }) {
    final orderIndex = currentStepOrderIndex;
    if (orderIndex == null) return const [];
    return currentRakaatSteps
        .where((step) => step.orderIndex == orderIndex)
        .toList(growable: false);
  }

  static List<RakaatStep> currentRecitationEntries({
    required List<RakaatStep> currentStepEntries,
  }) {
    return currentStepEntries
        .where(
          (step) =>
              step.arabic.trim().isNotEmpty ||
              step.transliteration.trim().isNotEmpty ||
              step.translation.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  static bool hasNextStageStep({
    required List<int> currentStepOrderIndexes,
    required int clampedStepIndex,
    required List<RakaatData> rakaats,
    required int rakaatIndex,
  }) {
    if (currentStepOrderIndexes.isEmpty) return false;
    if (clampedStepIndex < currentStepOrderIndexes.length - 1) return true;
    if (rakaats.isEmpty) return false;
    return rakaatIndex < rakaats.length - 1;
  }

  static bool hasPrevStageStep({
    required List<int> currentStepOrderIndexes,
    required int clampedStepIndex,
    required List<RakaatData> rakaats,
    required int rakaatIndex,
  }) {
    if (currentStepOrderIndexes.isEmpty) return false;
    if (clampedStepIndex > 0) return true;
    if (rakaats.isEmpty) return false;
    return rakaatIndex > 0;
  }

  static List<StagePageReference> allStagePages({
    required List<RakaatData> rakaats,
    required List<int> Function(int rakaatIndex) stepOrderIndexesForRakaatIndex,
  }) {
    final pages = <StagePageReference>[];
    for (var rakaatIndex = 0; rakaatIndex < rakaats.length; rakaatIndex++) {
      final orderIndexes = stepOrderIndexesForRakaatIndex(rakaatIndex);
      for (var stepIndex = 0; stepIndex < orderIndexes.length; stepIndex++) {
        pages.add(
          StagePageReference(rakaatIndex: rakaatIndex, stepIndex: stepIndex),
        );
      }
    }
    return pages;
  }

  static int currentFlatPageIndex({
    required List<StagePageReference> allStagePages,
    required int rakaatIndex,
    required int clampedStepIndex,
  }) {
    if (allStagePages.isEmpty) return 0;
    final index = allStagePages.indexWhere(
      (page) =>
          page.rakaatIndex == rakaatIndex && page.stepIndex == clampedStepIndex,
    );
    return index < 0 ? 0 : index;
  }

  static List<RakaatStep> entriesForPage({
    required List<RakaatData> rakaats,
    required int rakaatIndex,
    required int stepIndex,
    required List<int> Function(int rakaatIndex) stepOrderIndexesForRakaatIndex,
  }) {
    if (rakaats.isEmpty) return const [];
    final normalizedRakaat = rakaatIndex.clamp(0, rakaats.length - 1);
    final orderIndexes = stepOrderIndexesForRakaatIndex(normalizedRakaat);
    if (orderIndexes.isEmpty) return const [];
    final normalizedStep = stepIndex.clamp(0, orderIndexes.length - 1);
    final orderIndex = orderIndexes[normalizedStep];
    return rakaats[normalizedRakaat].steps
        .where((step) => step.orderIndex == orderIndex)
        .toList(growable: false);
  }

  static List<RakaatStep> recitationEntriesForPage({
    required List<RakaatData> rakaats,
    required int rakaatIndex,
    required int stepIndex,
    required List<int> Function(int rakaatIndex) stepOrderIndexesForRakaatIndex,
  }) {
    return entriesForPage(
          rakaats: rakaats,
          rakaatIndex: rakaatIndex,
          stepIndex: stepIndex,
          stepOrderIndexesForRakaatIndex: stepOrderIndexesForRakaatIndex,
        )
        .where(
          (step) =>
              step.arabic.trim().isNotEmpty ||
              step.transliteration.trim().isNotEmpty ||
              step.translation.trim().isNotEmpty,
        )
        .toList(growable: false);
  }
}
