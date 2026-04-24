import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryMemory implements OnboardingRepository {
  OnboardingRepositoryMemory._();

  static final OnboardingRepositoryMemory instance =
      OnboardingRepositoryMemory._();
  static const _completedStartKey = 'onboarding.start.completed';
  static const _completedStageKey = 'onboarding.stage.completed';

  bool _showStageOnboarding = false;
  bool _hasCompletedStart = false;
  bool _hasCompletedStage = false;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedStart = prefs.getBool(_completedStartKey) ?? false;
      _hasCompletedStage = prefs.getBool(_completedStageKey) ?? false;
    } catch (_) {}
  }

  bool get hasCompletedStart => _hasCompletedStart;

  void completeStartOnboarding() {
    _hasCompletedStart = true;
    _persistCompletedStart();
  }

  void completeStageOnboarding() {
    _hasCompletedStage = true;
    _showStageOnboarding = false;
    _persistCompletedStage();
  }

  @override
  void triggerStageOnboarding() {
    _showStageOnboarding = true;
  }

  @override
  bool consumeStageOnboarding() {
    final value = _showStageOnboarding || !_hasCompletedStage;
    _showStageOnboarding = false;
    return value;
  }

  Future<void> _persistCompletedStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedStartKey, true);
    } catch (_) {}
  }

  Future<void> _persistCompletedStage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedStageKey, true);
    } catch (_) {}
  }
}
