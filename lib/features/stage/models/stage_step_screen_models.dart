class StageSectionSelection {
  const StageSectionSelection(this.rakaatIndex, this.stepIndex);

  final int rakaatIndex;
  final int stepIndex;
}

class StagePageReference {
  const StagePageReference({
    required this.rakaatIndex,
    required this.stepIndex,
  });

  final int rakaatIndex;
  final int stepIndex;
}

class StageStepGroup {
  const StageStepGroup({required this.title});

  final String title;
}

class DisplayedStepProgress {
  const DisplayedStepProgress({required this.current, required this.total});

  final int current;
  final int total;
}
