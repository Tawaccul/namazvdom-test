import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryMemory implements OnboardingRepository {
  OnboardingRepositoryMemory._();

  static final OnboardingRepositoryMemory instance =
      OnboardingRepositoryMemory._();
  static const _completedStartKey = 'onboarding.start.completed';

  bool _showStageOnboarding = false;
  bool _hasCompletedStart = false;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedStart = prefs.getBool(_completedStartKey) ?? false;
    } catch (_) {}
  }

  bool get hasCompletedStart => _hasCompletedStart;

  void completeStartOnboarding() {
    _hasCompletedStart = true;
    _persistCompletedStart();
  }

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

  Future<void> _persistCompletedStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedStartKey, true);
    } catch (_) {}
  }
}
