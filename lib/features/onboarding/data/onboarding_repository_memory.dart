import '../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryMemory implements OnboardingRepository {
  OnboardingRepositoryMemory._();

  static final OnboardingRepositoryMemory instance =
      OnboardingRepositoryMemory._();

  bool _showStageOnboarding = false;

  @override
  void triggerStageOnboarding() {
    _showStageOnboarding = true;
  }

  @override
  bool consumeStageOnboarding() {
    final value = _showStageOnboarding;
    _showStageOnboarding = false;
    return value;
  }
}
