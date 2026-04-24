import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../app/app_dependencies_scope.dart';
import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/ui_kit/app_button.dart';
import '../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../core/audio/ayah_audio.dart';
import '../../core/audio/ayah_audio_controller.dart';
import '../../core/text/transliteration_localizer.dart';
import '../../core/widgets/pressable.dart';
import '../onboarding/data/onboarding_repository_memory.dart';
import '../prayer/domain/usecases/get_prayer_surah.dart';
import '../settings/gender/data/gender_repository_memory.dart';
import '../settings/language/data/language_repository_memory.dart';
import '../settings/theme/presentation/theme_text_size_store.dart';
import 'parts/stage_ayah_card.dart';
import 'parts/stage_bottom_button.dart';
import 'parts/stage_card.dart';
import 'parts/stage_pinned_progress.dart';
import 'parts/stage_progress_bar.dart';
import 'parts/stage_surah_selector.dart';
import 'parts/stage_top_bar.dart';
import 'stage_onboarding_overlay.dart';
import 'models/rakaat_models.dart';
import '../quran/model/quran_ayah.dart';
import 'stage_prayer_loader.dart';

class StageStepScreen extends StatefulWidget {
  const StageStepScreen({
    super.key,
    required this.rakaats,
    this.audio,
    this.prayerTitle = '',
    this.prayerCode = '',
  });

  final List<RakaatData> rakaats;
  final AyahAudio? audio;
  final String prayerTitle;
  final String prayerCode;

  @override
  State<StageStepScreen> createState() => _StageStepScreenState();
}

class _StageStepScreenState extends State<StageStepScreen>
    with SingleTickerProviderStateMixin {
  static const bool _alwaysShowStageOnboarding = false;
  static const double _topBlurShowOffset = 80;
  static const double _horizontalSwipeVelocityThreshold = 220;
  static const double _overviewOpenScaleThreshold = 0.99;
  static const double _overviewCloseScaleThreshold = 0.985;
  static const double _overviewPageGap = -10;
  static const double _overviewPreviewScale = 0.76;
  static const double _overviewDragFriction = 0.0000012;
  static const double _overviewPanSpeedMultiplier = 3.0;
  static const double _overviewClosingTopInset = 50;
  static const double _overviewPreviewTopShift = 10;
  static const double _overviewCanvasInset = 280;
  static const double _overviewFitPadding = 24;
  static const Duration _overviewMatrixDuration = Duration(milliseconds: 320);
  static const _randomStageAudioAssets = <String>[
    'assets/audio/730cbdbfa3d664506abd7c2baf719491.mp3',
    'assets/audio/istiaza.mp3',
    'assets/audio/takbir.mp3',
  ];

  late final AyahAudio _audio;
  late final math.Random _randomAudio;
  late final TransformationController _transformationController;
  late final AnimationController _overviewAnimationController;
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  final Map<String, ScrollController> _overviewScrollControllers = {};
  final Map<String, bool> _overviewOverflowByPage = {};
  final Map<String, GlobalKey> _stepKeys = {};
  final Map<String, String> _entryAudioUrls = {};
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _stageButtonKey = GlobalKey();
  bool _showPinned = false;
  bool _showTopBlur = false;
  bool _showOnboarding = false;
  bool _showOverviewLayer = false;
  bool _isOverviewClosing = false;
  bool _showOverviewExitButton = false;

  String? _error;
  late List<RakaatData> _rakaats;
  int _rakaatIndex = 0;
  int _stepIndex = 0;
  bool _autoplayEnabled = false;
  int _autoplaySessionId = 0;
  String? _playingStepKey;
  String? _startedPlaybackStepKey;
  bool _contentAppeared = false;
  int _selectedAyahIndex = 0;
  String? _selectedAdditionalSurahCode;
  final Map<String, bool> _assetExistsMemo = {};
  bool _isOverviewMode = false;
  int _overviewSelectedFlatIndex = 0;
  int _overviewOriginFlatIndex = 0;
  bool _scaleGestureTriggered = false;
  bool _isAnimatingOverviewMatrix = false;
  bool _isClampingOverviewTransform = false;
  bool _isStageTransitioning = false;
  bool _overviewPinchCloseTriggered = false;
  bool _overviewGestureLock = false;
  int? _overviewPendingCloseFlatIndex;
  bool _showTopControls = true;
  int _topControlsRevealToken = 0;
  int _stepTransitionToken = 0;
  int _stepTransitionDirection = 1;
  bool _allowExitPop = false;
  int _onboardingStepIndex = 0;
  bool _onboardingStepAdvancing = false;

  @override
  void initState() {
    super.initState();

    _randomAudio = math.Random();
    _transformationController = TransformationController();
    _transformationController.addListener(_handleOverviewTransformChanged);
    _overviewAnimationController = AnimationController(
      vsync: this,
      duration: _overviewMatrixDuration,
    );
    _rakaats = widget.rakaats;
    _audio = widget.audio ?? AyahAudioController();
    _audio.addListener(_onAudioTick);
    if (_selectedAyahStep?.hasAudio ?? false) {
      _audio.setAyah(_stepToAyah(_selectedAyahStep!, _stepKey));
    }
    _scrollController.addListener(_onScroll);
    _showOnboarding =
        _alwaysShowStageOnboarding ||
        OnboardingRepositoryMemory.instance.consumeStageOnboarding();
    _onboardingStepIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updatePinned();
      setState(() => _contentAppeared = true);
    });
  }

  void _onAudioTick() {
    final stepKey = _stepKey;
    final isPlaying = _audio.isPlaying;
    if (_playingStepKey == stepKey && isPlaying) {
      _startedPlaybackStepKey = stepKey;
    }
    if (mounted) setState(() {});
  }

  List<RakaatSurahOption> get _additionalSurahOptions =>
      _currentRakaat?.additionalSurahOptions ?? const [];

  bool _isAdditionalSurahStep(RakaatStep? step) {
    if (step == null) return false;
    return step.stepCode.trim().toLowerCase() == 'additional_surah' ||
        step.additionalSurahOptionCode.trim().isNotEmpty;
  }

  int _selectedAdditionalSurahIndex(List<RakaatSurahOption> options) {
    return _selectedAdditionalSurahIndexForStep(options, _currentStep);
  }

  int _selectedAdditionalSurahIndexForStep(
    List<RakaatSurahOption> options,
    RakaatStep? step,
  ) {
    if (options.isEmpty) return 0;
    final currentCode = step?.additionalSurahOptionCode.trim() ?? '';
    if (currentCode.isNotEmpty) {
      final fromCurrent = options.indexWhere(
        (item) => item.code == currentCode,
      );
      if (fromCurrent >= 0) return fromCurrent;
    }
    final selectedCode = _selectedAdditionalSurahCode?.trim() ?? '';
    if (selectedCode.isNotEmpty) {
      final fromState = options.indexWhere((item) => item.code == selectedCode);
      if (fromState >= 0) return fromState;
    }
    final ikhlasIndex = options.indexWhere((item) => item.code == 'al_ikhlas');
    if (ikhlasIndex >= 0) return ikhlasIndex;
    return 0;
  }

  Future<void> _onSelectAdditionalSurah({
    required List<RakaatSurahOption> options,
    required int optionIndex,
  }) async {
    if (optionIndex < 0 || optionIndex >= options.length) return;
    final option = options[optionIndex];
    setState(() => _selectedAdditionalSurahCode = option.code);
    try {
      final targetStepIndex = await _replaceAdditionalSurahSteps(option);
      if (targetStepIndex == null) return;
      _autoplayEnabled = false;
      await _selectStep(targetStepIndex, playIfAutoplay: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<int?> _replaceAdditionalSurahSteps(RakaatSurahOption option) async {
    final rakaat = _currentRakaat;
    if (rakaat == null) return null;
    final steps = [...rakaat.steps];
    final guideIndex = steps.indexWhere(
      (step) =>
          step.stepCode.trim().toLowerCase() == 'additional_surah' &&
          step.additionalSurahOptionCode.trim().isEmpty,
    );
    if (guideIndex < 0) return null;
    final guideOrderIndex = steps[guideIndex].orderIndex;

    steps.removeWhere(
      (step) =>
          step.stepCode.trim().toLowerCase() == 'additional_surah' &&
          step.additionalSurahOptionCode.trim().isNotEmpty,
    );

    final repository = AppDependenciesScope.prayerRepositoryOf(context);
    final getPrayerSurah = GetPrayerSurah(repository);
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    final audioUrl = await _resolveAudioAssetPath(
      rakah: rakaat.number,
      stepCode: 'additional_surah',
    );
    List<RakaatStep> inserted = const [];
    if (StagePrayerLoader.forceLocalOnly) {
      inserted = await _loadLocalAdditionalSurahSteps(
        surahCode: option.code,
        title: option.label,
        orderIndex: steps[guideIndex].orderIndex,
        audioUrl: audioUrl,
      );
      if (inserted.isEmpty) return null;
    } else {
      try {
        final surah = await getPrayerSurah(
          surahCode: option.code,
          languageCode: languageCode,
        );
        inserted = surah.ayahs
            .map(
              (ayah) => RakaatStep(
                orderIndex: steps[guideIndex].orderIndex,
                title: option.label,
                movementDescription: '',
                arabic: ayah.recitationArabic,
                transliteration: localizedTransliteration(
                  ayah.transliteration,
                  languageCode,
                ),
                translation: ayah.translation,
                stepCode: 'additional_surah',
                audioUrl: audioUrl,
                surahCode: option.code,
                additionalSurahOptionCode: option.code,
              ),
            )
            .toList(growable: false);
      } catch (_) {
        inserted = await _loadLocalAdditionalSurahSteps(
          surahCode: option.code,
          title: option.label,
          orderIndex: steps[guideIndex].orderIndex,
          audioUrl: audioUrl,
        );
        if (inserted.isEmpty) rethrow;
      }
    }
    steps.insertAll(guideIndex + 1, inserted);

    final updatedRakaats = [..._rakaats];
    updatedRakaats[_rakaatIndex] = RakaatData(
      number: rakaat.number,
      imageAsset: rakaat.imageAsset,
      steps: steps,
      additionalSurahOptions: rakaat.additionalSurahOptions,
    );
    if (!mounted) return null;
    setState(() => _rakaats = updatedRakaats);
    final stepOrders = <int>{};
    for (final step in updatedRakaats[_rakaatIndex].steps) {
      stepOrders.add(step.orderIndex);
    }
    final ordered = stepOrders.toList()..sort();
    final mappedIndex = ordered.indexOf(guideOrderIndex);
    if (mappedIndex < 0) return null;
    return mappedIndex;
  }

  Future<String> _resolveAudioAssetPath({
    required int rakah,
    required String stepCode,
  }) async {
    final normalizedStepCode = stepCode.trim().toLowerCase();
    if (normalizedStepCode.isEmpty) return '';

    final byRakah = 'assets/audio/prayer/${rakah}_$normalizedStepCode.mp3';
    if (await _assetExists(byRakah)) return byRakah;

    final byStepCode = 'assets/audio/prayer/$normalizedStepCode.mp3';
    if (await _assetExists(byStepCode)) return byStepCode;

    final legacyByStepCode = 'assets/audio/$normalizedStepCode.mp3';
    if (await _assetExists(legacyByStepCode)) return legacyByStepCode;

    return '';
  }

  Future<bool> _assetExists(String path) async {
    final memo = _assetExistsMemo[path];
    if (memo != null) return memo;
    try {
      await rootBundle.load(path);
      _assetExistsMemo[path] = true;
      return true;
    } catch (_) {
      _assetExistsMemo[path] = false;
      return false;
    }
  }

  Future<List<RakaatStep>> _loadLocalAdditionalSurahSteps({
    required String surahCode,
    required String title,
    required int orderIndex,
    required String audioUrl,
  }) async {
    final normalized = surahCode.trim().toLowerCase();
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    if (normalized.isEmpty) return const [];
    final assetPath = 'assets/surahs/$normalized.json';
    if (!await _assetExists(assetPath)) return const [];

    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw);
      if (json is! Map) return const [];
      final rows =
          (json.cast<String, dynamic>()['ayahs'] as List?)?.cast<dynamic>() ??
          const [];
      final ayahs = <RakaatStep>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = row.cast<String, dynamic>();
        final arabic =
            (map['arabic'] as String? ??
                    map['recitationArabic'] as String? ??
                    '')
                .trim();
        final transliteration = localizedTransliteration(
          (map['transliteration'] as String? ?? '').trim(),
          languageCode,
        );
        final translation = _translateKey(
          map['translation_key'] as String?,
          fallback: (map['translation'] as String? ?? '').trim(),
        );
        if (arabic.isEmpty && transliteration.isEmpty && translation.isEmpty) {
          continue;
        }
        ayahs.add(
          RakaatStep(
            orderIndex: orderIndex,
            title: title,
            movementDescription: '',
            arabic: arabic,
            transliteration: transliteration,
            translation: translation,
            stepCode: 'additional_surah',
            audioUrl: audioUrl,
            surahCode: normalized,
            additionalSurahOptionCode: normalized,
          ),
        );
      }
      return ayahs.toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  String _translateKey(String? key, {String fallback = ''}) {
    final normalized = (key ?? '').trim();
    if (normalized.isEmpty) return fallback;
    final translated = context.t(normalized);
    if (translated == normalized) {
      return fallback.isEmpty ? normalized : fallback;
    }
    return translated;
  }

  void _jumpToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  Future<void> _animateToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleOnboardingStepChanged(int stepIndex) {
    if (stepIndex != 2) return;
    _scrollOnboardingStepIntoView();
  }

  void _scrollOnboardingStepIntoView({int attempt = 0}) {
    final ctx = _stepKeys[_entryKey(_clampedAyahIndex)]?.currentContext;
    if (ctx == null) {
      if (attempt >= 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_showOnboarding) return;
        _scrollOnboardingStepIntoView(attempt: attempt + 1);
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showOnboarding) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      ).then((_) {
        if (!mounted || !_showOnboarding) return;
        setState(() {});
      });
    });
  }

  void _onOnboardingNext() {
    if (!_showOnboarding || _onboardingStepAdvancing) return;
    _onboardingStepAdvancing = true;
    HapticFeedback.mediumImpact();
    if (_onboardingStepIndex >= 2) {
      _finishOnboarding();
      _onboardingStepAdvancing = false;
      return;
    }
    final nextStep = _onboardingStepIndex + 1;
    setState(() => _onboardingStepIndex = nextStep);
    _handleOnboardingStepChanged(nextStep);
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _onboardingStepAdvancing = false;
    });
  }

  void _triggerLightHaptic() {
    HapticFeedback.lightImpact();
  }

  void _finishOnboarding() {
    if (!_showOnboarding) return;
    OnboardingRepositoryMemory.instance.completeStageOnboarding();
    setState(() {
      _showOnboarding = false;
      _onboardingStepIndex = 0;
      _onboardingStepAdvancing = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animateToTop();
    });
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioTick);
    _audio.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (final controller in _overviewScrollControllers.values) {
      controller.dispose();
    }
    _transformationController.removeListener(_handleOverviewTransformChanged);
    _overviewAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  String _overviewPageId(_StagePageReference page) =>
      '${page.rakaatIndex}-${page.stepIndex}';

  ScrollController _overviewScrollControllerFor(String pageId) {
    return _overviewScrollControllers.putIfAbsent(
      pageId,
      () => ScrollController(keepScrollOffset: false),
    );
  }

  void _setOverviewOverflow(String pageId, bool hasOverflow) {
    final previous = _overviewOverflowByPage[pageId] ?? false;
    if (previous == hasOverflow) return;
    if (!mounted) return;
    setState(() => _overviewOverflowByPage[pageId] = hasOverflow);
  }

  void _onScroll() {
    if (_showOverviewLayer) {
      if (_showPinned) {
        setState(() => _showPinned = false);
      }
      if (_showTopBlur) {
        setState(() => _showTopBlur = false);
      }
      return;
    }
    _updatePinned();
    _updateTopBlur();
  }

  void _updateTopBlur() {
    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _topBlurShowOffset;
    if (shouldShow == _showTopBlur) return;
    setState(() => _showTopBlur = shouldShow);
  }

  void _updatePinned() {
    final progressCtx = _progressKey.currentContext;
    final stackBox = context.findRenderObject() as RenderBox?;
    if (progressCtx == null || stackBox == null) return;
    final progressBox = progressCtx.findRenderObject() as RenderBox?;
    if (progressBox == null || !progressBox.hasSize) return;
    final stackTop = stackBox.localToGlobal(Offset.zero).dy;
    final progressTop = progressBox.localToGlobal(Offset.zero).dy - stackTop;
    final progressBottom = progressTop + progressBox.size.height;
    final pinnedTop = 64.h;
    final shouldShow = progressBottom <= pinnedTop + 4.h;
    if (shouldShow != _showPinned) {
      setState(() => _showPinned = shouldShow);
    }
  }

  RakaatData? get _currentRakaat => _rakaats.isEmpty
      ? null
      : _rakaats[_rakaatIndex.clamp(0, _rakaats.length - 1)];

  List<RakaatStep> get _currentRakaatSteps => _currentRakaat?.steps ?? const [];

  int _stepCountForRakaat(int rakaatIndex) {
    if (_rakaats.isEmpty) return 0;
    final index = rakaatIndex.clamp(0, _rakaats.length - 1);
    final set = <int>{};
    for (final step in _rakaats[index].steps) {
      set.add(step.orderIndex);
    }
    return set.length;
  }

  bool get _hasNextStageStep {
    if (_currentStepOrderIndexes.isEmpty) return false;
    if (_clampedStepIndex < _currentStepOrderIndexes.length - 1) return true;
    if (_rakaats.isEmpty) return false;
    return _rakaatIndex < _rakaats.length - 1;
  }

  bool get _hasPrevStageStep {
    if (_currentStepOrderIndexes.isEmpty) return false;
    if (_clampedStepIndex > 0) return true;
    if (_rakaats.isEmpty) return false;
    return _rakaatIndex > 0;
  }

  List<int> get _currentStepOrderIndexes {
    final set = <int>{};
    for (final step in _currentRakaatSteps) {
      set.add(step.orderIndex);
    }
    final indexes = set.toList()..sort();
    return indexes;
  }

  int get _clampedStepIndex {
    if (_currentStepOrderIndexes.isEmpty) return 0;
    return _stepIndex.clamp(0, _currentStepOrderIndexes.length - 1);
  }

  int? get _currentStepOrderIndex => _currentStepOrderIndexes.isEmpty
      ? null
      : _currentStepOrderIndexes[_clampedStepIndex];

  List<RakaatStep> get _currentStepEntries {
    final orderIndex = _currentStepOrderIndex;
    if (orderIndex == null) return const [];
    return _currentRakaatSteps
        .where((step) => step.orderIndex == orderIndex)
        .toList(growable: false);
  }

  RakaatStep? get _currentStep => _currentStepEntries.firstOrNull;

  List<RakaatStep> get _currentRecitationEntries => _currentStepEntries
      .where(
        (step) =>
            step.arabic.trim().isNotEmpty ||
            step.transliteration.trim().isNotEmpty ||
            step.translation.trim().isNotEmpty,
      )
      .toList(growable: false);

  int get _clampedAyahIndex {
    if (_currentRecitationEntries.isEmpty) return 0;
    return _selectedAyahIndex.clamp(0, _currentRecitationEntries.length - 1);
  }

  RakaatStep? get _selectedAyahStep => _currentRecitationEntries.isEmpty
      ? null
      : _currentRecitationEntries[_clampedAyahIndex];

  String _entryKey(int ayahIndex) {
    final orderIndex = _currentStepOrderIndex ?? -1;
    return 'r$_rakaatIndex-o$orderIndex-a$ayahIndex';
  }

  String get _stepKey => _entryKey(_clampedAyahIndex);

  String _audioUrlForEntry(String entryKey) {
    return _entryAudioUrls.putIfAbsent(
      entryKey,
      () =>
          _randomStageAudioAssets[_randomAudio.nextInt(
            _randomStageAudioAssets.length,
          )],
    );
  }

  void _cancelAutoplaySequence({bool disableAutoplay = false}) {
    _autoplaySessionId++;
    if (disableAutoplay) {
      _autoplayEnabled = false;
    }
  }

  bool _isAutoplaySessionActive(int sessionId) {
    return mounted && _autoplayEnabled && sessionId == _autoplaySessionId;
  }

  Future<bool> _waitForPlaybackCompletion(int sessionId, String stepKey) {
    final completer = Completer<bool>();
    var lastWasPlaying = _audio.isPlaying;

    void finish(bool value, VoidCallback listener) {
      if (completer.isCompleted) return;
      _audio.removeListener(listener);
      completer.complete(value);
    }

    late final VoidCallback listener;
    listener = () {
      if (!_isAutoplaySessionActive(sessionId) || _playingStepKey != stepKey) {
        finish(false, listener);
        return;
      }
      final isPlaying = _audio.isPlaying;
      if (_playingStepKey == stepKey && isPlaying) {
        _startedPlaybackStepKey = stepKey;
      }
      final reachedEnd = _audio.progress >= 0.98;
      final completedByProgress = !isPlaying && lastWasPlaying && reachedEnd;
      final completed =
          _startedPlaybackStepKey == stepKey &&
          (_audio.isCompleted || completedByProgress);
      lastWasPlaying = isPlaying;
      if (completed) {
        finish(true, listener);
      }
    };

    _audio.addListener(listener);
    listener();
    return completer.future;
  }

  Future<void> _startPageAutoplayFrom(int ayahIndex) async {
    if (_currentRecitationEntries.isEmpty) return;
    _cancelAutoplaySequence();
    _autoplayEnabled = true;
    final sessionId = _autoplaySessionId;
    final startIndex = ayahIndex.clamp(0, _currentRecitationEntries.length - 1);

    try {
      for (var i = startIndex; i < _currentRecitationEntries.length; i++) {
        if (!_isAutoplaySessionActive(sessionId)) return;
        await _selectAyahInCurrentStep(i, playIfAutoplay: false);
        if (!_isAutoplaySessionActive(sessionId)) return;
        final currentStepKey = _stepKey;
        await _playCurrent();
        final completed = await _waitForPlaybackCompletion(
          sessionId,
          currentStepKey,
        );
        if (!completed) return;
        if (i < _currentRecitationEntries.length - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
      if (!_isAutoplaySessionActive(sessionId)) return;
      await _dismissFloatingPlayer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  QuranAyah _stepToAyah(RakaatStep step, String id) {
    return QuranAyah(
      surahId: 0,
      ayahId: id.hashCode,
      surahNameAr: '',
      surahNameEn: '',
      ayahCount: 0,
      ayahAr: step.arabic,
      ayahEn: step.translation,
      ayahTr: step.transliteration,
      reciterId: 'custom',
      reciterName: 'custom',
      audioUrl: _audioUrlForEntry(id),
    );
  }

  Future<void> _togglePlay() async {
    final step = _selectedAyahStep;
    if (step == null || !step.hasAudio) return;
    try {
      if (_audio.isPlaying) {
        await _audio.pause();
        if (mounted) {
          setState(() {});
        }
        return;
      }

      if (_playingStepKey == _stepKey) {
        await _audio.play();
        if (mounted) {
          setState(() {});
        }
        return;
      }

      if (_currentRecitationEntries.isNotEmpty) {
        await _startPageAutoplayFrom(_clampedAyahIndex);
      } else {
        await _audio.setAyah(_stepToAyah(step, _stepKey));
        await _playCurrent();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _playCurrent() async {
    final step = _selectedAyahStep;
    if (step == null || !step.hasAudio) return;
    _playingStepKey = _stepKey;
    _startedPlaybackStepKey = null;
    if (mounted) {
      setState(() {});
    }
    await _audio.play();
  }

  Future<void> _dismissFloatingPlayer() async {
    _cancelAutoplaySequence(disableAutoplay: true);
    _playingStepKey = null;
    _startedPlaybackStepKey = null;
    if (mounted) {
      setState(() {});
    }
    await _audio.pause();
  }

  Future<void> _playStepAt(int ayahIndex) async {
    if (_currentRecitationEntries.isEmpty) return;
    await _startPageAutoplayFrom(ayahIndex);
  }

  Future<void> _selectAyahInCurrentStep(
    int ayahIndex, {
    bool playIfAutoplay = true,
  }) async {
    if (_currentRecitationEntries.isEmpty) return;
    final next = ayahIndex.clamp(0, _currentRecitationEntries.length - 1);
    setState(() => _selectedAyahIndex = next);
    final step = _selectedAyahStep;
    if (step == null) return;
    if (step.hasAudio) {
      await _audio.setAyah(_stepToAyah(step, _stepKey));
    }
    _playingStepKey = null;
    _startedPlaybackStepKey = null;
    if (playIfAutoplay && _autoplayEnabled && step.hasAudio) {
      await _playCurrent();
    }
  }

  Future<void> _selectStep(
    int index, {
    bool playIfAutoplay = true,
    int direction = 1,
  }) async {
    if (_currentStepOrderIndexes.isEmpty) return;
    final next = index.clamp(0, _currentStepOrderIndexes.length - 1);
    await _selectRakaatAndStep(
      _rakaatIndex,
      next,
      playIfAutoplay: playIfAutoplay,
      direction: direction,
    );
  }

  Future<void> _selectRakaatAndStep(
    int rakaatIndex,
    int stepIndex, {
    bool playIfAutoplay = false,
    int direction = 1,
    bool animateStepTransition = true,
  }) async {
    if (_rakaats.isEmpty || _isStageTransitioning) return;
    _isStageTransitioning = true;
    try {
      final nextRakaat = rakaatIndex.clamp(0, _rakaats.length - 1);
      final stepCount = _stepCountForRakaat(nextRakaat);
      final nextStep = stepCount == 0 ? 0 : stepIndex.clamp(0, stepCount - 1);
      final resumeAutoplay = playIfAutoplay && _autoplayEnabled;

      _cancelAutoplaySequence(disableAutoplay: true);
      _playingStepKey = null;
      _startedPlaybackStepKey = null;
      await _audio.pause();
      if (!mounted) return;

      setState(() {
        _rakaatIndex = nextRakaat;
        _stepIndex = nextStep;
        _selectedAyahIndex = 0;
        _showPinned = false;
        if (animateStepTransition) {
          _stepTransitionToken++;
          _stepTransitionDirection = direction >= 0 ? 1 : -1;
        }
      });
      _jumpToTop();

      final step = _selectedAyahStep;
      if (step == null) return;
      if (step.hasAudio) {
        await _audio.setAyah(_stepToAyah(step, _stepKey));
      }
      if (resumeAutoplay && step.hasAudio) {
        await _playCurrent();
      }
    } finally {
      _isStageTransitioning = false;
    }
  }

  List<int> _stepOrderIndexesForRakaatIndex(int rakaatIndex) {
    if (_rakaats.isEmpty) return const [];
    final normalized = rakaatIndex.clamp(0, _rakaats.length - 1);
    final set = <int>{};
    for (final step in _rakaats[normalized].steps) {
      set.add(step.orderIndex);
    }
    final indexes = set.toList()..sort();
    return indexes;
  }

  List<_StagePageReference> get _allStagePages {
    final pages = <_StagePageReference>[];
    for (var rakaatIndex = 0; rakaatIndex < _rakaats.length; rakaatIndex++) {
      final orderIndexes = _stepOrderIndexesForRakaatIndex(rakaatIndex);
      for (var stepIndex = 0; stepIndex < orderIndexes.length; stepIndex++) {
        pages.add(
          _StagePageReference(rakaatIndex: rakaatIndex, stepIndex: stepIndex),
        );
      }
    }
    return pages;
  }

  int get _currentFlatPageIndex {
    final pages = _allStagePages;
    if (pages.isEmpty) return 0;
    final index = pages.indexWhere(
      (page) =>
          page.rakaatIndex == _rakaatIndex &&
          page.stepIndex == _clampedStepIndex,
    );
    return index < 0 ? 0 : index;
  }

  List<RakaatStep> _entriesForPage({
    required int rakaatIndex,
    required int stepIndex,
  }) {
    if (_rakaats.isEmpty) return const [];
    final normalizedRakaat = rakaatIndex.clamp(0, _rakaats.length - 1);
    final orderIndexes = _stepOrderIndexesForRakaatIndex(normalizedRakaat);
    if (orderIndexes.isEmpty) return const [];
    final normalizedStep = stepIndex.clamp(0, orderIndexes.length - 1);
    final orderIndex = orderIndexes[normalizedStep];
    return _rakaats[normalizedRakaat].steps
        .where((step) => step.orderIndex == orderIndex)
        .toList(growable: false);
  }

  List<RakaatStep> _recitationEntriesForPage({
    required int rakaatIndex,
    required int stepIndex,
  }) {
    return _entriesForPage(rakaatIndex: rakaatIndex, stepIndex: stepIndex)
        .where(
          (step) =>
              step.arabic.trim().isNotEmpty ||
              step.transliteration.trim().isNotEmpty ||
              step.translation.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  Size _overviewViewportSize() {
    final size = MediaQuery.sizeOf(context);
    return Size(size.width, size.height);
  }

  double _overviewRestingTopInset() {
    return math.max(
      MediaQuery.paddingOf(context).top,
      _overviewClosingTopInset.h,
    );
  }

  double _overviewPreviewTopInset() {
    return math.max(
      MediaQuery.paddingOf(context).top,
      _overviewRestingTopInset() - _overviewPreviewTopShift.h,
    );
  }

  double _overviewTopInsetForScale(double scale) {
    final normalized =
        ((scale - _overviewPreviewScale) / (1 - _overviewPreviewScale)).clamp(
          0.0,
          1.0,
        );
    return ui.lerpDouble(
          _overviewPreviewTopInset(),
          _overviewRestingTopInset(),
          normalized,
        ) ??
        _overviewRestingTopInset();
  }

  Size _overviewCardSize() => _overviewViewportSize();

  int _flatIndexForPageReference(int rakaatIndex, int stepIndex) {
    final pages = _allStagePages;
    final index = pages.indexWhere(
      (page) => page.rakaatIndex == rakaatIndex && page.stepIndex == stepIndex,
    );
    return index < 0 ? 0 : index;
  }

  Offset _getCardPosition(int rakaatIndex, int stepIndex) {
    final size = _overviewCardSize();
    final flatIndex = _flatIndexForPageReference(rakaatIndex, stepIndex);
    final x =
        _overviewCanvasInset + flatIndex * (size.width + _overviewPageGap);
    final y = _overviewCanvasInset;
    return Offset(x, y);
  }

  Rect _overviewContentRect() {
    final size = _overviewCardSize();
    final pageCount = math.max(_allStagePages.length, 1);
    final width = pageCount * size.width + (pageCount - 1) * _overviewPageGap;
    final height = size.height;
    return Rect.fromLTWH(
      _overviewCanvasInset,
      _overviewCanvasInset,
      width,
      height,
    );
  }

  Size _overviewCanvasSize() {
    final rect = _overviewContentRect();
    return Size(
      rect.right + _overviewCanvasInset,
      rect.bottom + _overviewCanvasInset,
    );
  }

  Rect _overviewCardRect(_StagePageReference page) {
    final size = _overviewCardSize();
    final position = _getCardPosition(page.rakaatIndex, page.stepIndex);
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  Matrix4 _overviewMatrixForPage(_StagePageReference page, {double scale = 1}) {
    final viewport = _overviewViewportSize();
    final rect = _overviewCardRect(page);
    final dx =
        (viewport.width - (rect.width * scale)) / 2 - (rect.left * scale);
    final topInset = _overviewTopInsetForScale(scale);
    final dy = topInset - (rect.top * scale);
    final matrix = Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
    matrix.setTranslationRaw(dx, dy, 0);
    return matrix;
  }

  void _handleOverviewTransformChanged() {
    if (!_showOverviewLayer ||
        _isAnimatingOverviewMatrix ||
        _isClampingOverviewTransform) {
      return;
    }
    final clamped = _clampOverviewTransform(_transformationController.value);
    final current = _transformationController.value;
    if (_matricesAreEqual(current, clamped)) {
      return;
    }
    _isClampingOverviewTransform = true;
    _transformationController.value = clamped;
    _isClampingOverviewTransform = false;
  }

  void _handleOverviewPanUpdate(ScaleUpdateDetails details) {
    if (_isAnimatingOverviewMatrix || _isClampingOverviewTransform) return;
    if (_overviewGestureLock) return;
    if (_overviewPinchCloseTriggered) return;
    if (details.pointerCount >= 2) {
      final targetFlatIndex = _flatIndexForViewportPoint(
        details.localFocalPoint,
      );
      _overviewPendingCloseFlatIndex = targetFlatIndex;
      if (_overviewSelectedFlatIndex != targetFlatIndex && mounted) {
        setState(() => _overviewSelectedFlatIndex = targetFlatIndex);
      }
      final currentScale = _transformationController.value.storage[0]
          .clamp(_overviewPreviewScale, 1.0)
          .toDouble();
      if (details.scale >= _overviewCloseScaleThreshold ||
          currentScale >= _overviewCloseScaleThreshold) {
        _overviewPinchCloseTriggered = true;
        final closestFlatIndex =
            _overviewPendingCloseFlatIndex ??
            _nearestFlatIndexFromCurrentTransform();
        _transformationController.value = _overviewMatrixForPage(
          _pageForFlatIndex(closestFlatIndex)!,
          scale: _overviewPreviewScale,
        );
        if (mounted) {
          setState(() {
            _overviewSelectedFlatIndex = closestFlatIndex;
            _overviewGestureLock = true;
          });
        }
        unawaited(_closeOverviewFromPinch());
      }
      return;
    }
    final extraDx =
        details.focalPointDelta.dx * (_overviewPanSpeedMultiplier - 1);
    if (extraDx.abs() < 0.01) return;
    final boosted = Matrix4.copy(_transformationController.value)
      ..translateByDouble(extraDx, 0, 0, 1);
    _isClampingOverviewTransform = true;
    _transformationController.value = _clampOverviewTransform(boosted);
    _isClampingOverviewTransform = false;
  }

  void _handleOverviewInteractionStart(ScaleStartDetails details) {
    _overviewPinchCloseTriggered = false;
    _overviewPendingCloseFlatIndex = null;
    _overviewGestureLock = false;
  }

  void _handleOverviewInteractionEnd(ScaleEndDetails details) {
    if (!_overviewPinchCloseTriggered) {
      _overviewGestureLock = false;
    }
  }

  Matrix4 _clampOverviewTransform(Matrix4 matrix) {
    final rect = _overviewContentRect();
    final next = Matrix4.copy(matrix);
    final scale = next.storage[0].clamp(_overviewPreviewScale, 1.0).toDouble();
    final viewport = _overviewViewportSize();
    
    // Горизонтальные ограничения (оставляем скролл влево-вправо)
    final minDx = viewport.width - _overviewFitPadding - (rect.right * scale);
    final maxDx = _overviewFitPadding - (rect.left * scale);
    final rawDx = next.storage[12];
    final clampedDx = rawDx.clamp(minDx, maxDx).toDouble();
    
    // Вертикальные ограничения - ЖЕСТКАЯ ФИКСАЦИЯ
    // Это запретит любое смещение вверх/вниз
    final clampedDy = _overviewTopInsetForScale(scale) - (rect.top * scale);

    next.storage[0] = scale;
    next.storage[5] = scale;
    next.storage[10] = 1;
    next.storage[12] = clampedDx;
    next.storage[13] = clampedDy;
    next.storage[14] = 0;
    return next;
  }
  bool _matricesAreEqual(Matrix4 a, Matrix4 b) {
    for (var i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  Future<void> _animateOverviewMatrix(
    Matrix4 target, {
    Duration duration = _overviewMatrixDuration,
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!mounted) return;
    _overviewAnimationController
      ..stop()
      ..duration = duration
      ..reset();
    final animation =
        Matrix4Tween(
          begin: Matrix4.copy(_transformationController.value),
          end: target,
        ).animate(
          CurvedAnimation(parent: _overviewAnimationController, curve: curve),
        );

    void listener() {
      _transformationController.value = animation.value;
    }

    _isAnimatingOverviewMatrix = true;
    animation.addListener(listener);
    try {
      await _overviewAnimationController.forward();
    } finally {
      animation.removeListener(listener);
      _transformationController.value = target;
      _isAnimatingOverviewMatrix = false;
    }
  }

  Future<void> _openOverviewMode() async {
    if (_isOverviewMode ||
        _showOverviewLayer ||
        _isAnimatingOverviewMatrix ||
        _isStageTransitioning) {
      return;
    }
    final currentPage = _pageForFlatIndex(_currentFlatPageIndex);
    if (currentPage == null) return;
    _cancelAutoplaySequence(disableAutoplay: true);
    _playingStepKey = null;
    _startedPlaybackStepKey = null;
    await _audio.pause();
    if (!mounted) return;
    final currentFlatIndex = _currentFlatPageIndex;
    _topControlsRevealToken++;
    _transformationController.value = _overviewMatrixForPage(currentPage);
    setState(() {
      _overviewOriginFlatIndex = currentFlatIndex;
      _overviewSelectedFlatIndex = currentFlatIndex;
      _overviewPinchCloseTriggered = false;
      _overviewGestureLock = false;
      _overviewPendingCloseFlatIndex = null;
      _showTopControls = false;
      _showOverviewLayer = true;
      _isOverviewMode = true;
      _isOverviewClosing = false;
      _showOverviewExitButton = true;
      _showPinned = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showOverviewLayer) return;
      unawaited(
        _animateOverviewMatrix(
          _overviewMatrixForPage(currentPage, scale: _overviewPreviewScale),
          curve: Curves.easeInOutCubic,
        ),
      );
    });
  }

  Future<void> _closeOverviewMode({bool applySelection = false}) async {
    if (!_showOverviewLayer || _isAnimatingOverviewMatrix) return;
    _scaleGestureTriggered = false;
    _overviewPinchCloseTriggered = false;
    _overviewPendingCloseFlatIndex = null;
    final targetFlatIndex = applySelection
        ? _overviewSelectedFlatIndex
        : _overviewOriginFlatIndex;
    final selected = _pageForFlatIndex(targetFlatIndex);
    if (selected == null) {
      setState(() {
        _showOverviewLayer = false;
        _isOverviewMode = false;
        _isOverviewClosing = false;
        _showOverviewExitButton = false;
        _overviewGestureLock = false;
      });
      _scheduleTopControlsReveal();
      return;
    }
    setState(() {
      _isOverviewClosing = true;
      _showOverviewExitButton = false;
      _showPinned = false;
    });
    await _animateOverviewMatrix(
      _overviewMatrixForPage(selected),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    if (applySelection) {
      final direction = selected.rakaatIndex == _rakaatIndex
          ? (selected.stepIndex >= _clampedStepIndex ? 1 : -1)
          : (selected.rakaatIndex >= _rakaatIndex ? 1 : -1);
      await _selectRakaatAndStep(
        selected.rakaatIndex,
        selected.stepIndex,
        playIfAutoplay: false,
        direction: direction,
        animateStepTransition: false,
      );
    }
    if (!mounted) return;
    setState(() {
      _showOverviewLayer = false;
      _isOverviewMode = false;
      _isOverviewClosing = false;
      _showOverviewExitButton = false;
      _showPinned = false;
      _overviewGestureLock = false;
    });
    _scheduleTopControlsReveal();
  }

  void _scheduleTopControlsReveal() {
    final token = ++_topControlsRevealToken;
    Future<void>.delayed(Duration.zero, () {
      if (!mounted) return;
      if (token != _topControlsRevealToken) return;
      if (_showOverviewLayer) return;
      if (_showTopControls) return;
      setState(() => _showTopControls = true);
    });
  }

  _StagePageReference? _pageForFlatIndex(int flatIndex) {
    final pages = _allStagePages;
    if (pages.isEmpty) return null;
    return pages[flatIndex.clamp(0, pages.length - 1)];
  }

  Future<void> _closeOverviewFromPinch() async {
    if (!_showOverviewLayer || _isAnimatingOverviewMatrix) return;
    final targetFlatIndex =
        _overviewPendingCloseFlatIndex ?? _overviewSelectedFlatIndex;
    final selected = _pageForFlatIndex(targetFlatIndex);
    if (selected == null) return;
    if (_overviewSelectedFlatIndex != targetFlatIndex && mounted) {
      setState(() => _overviewSelectedFlatIndex = targetFlatIndex);
    }
    _transformationController.value = _overviewMatrixForPage(
      selected,
      scale: _overviewPreviewScale,
    );
    _overviewPinchCloseTriggered = true;
    _overviewGestureLock = true;
    _overviewPendingCloseFlatIndex = null;
    await _closeOverviewMode(applySelection: true);
  }

  int _nearestFlatIndexFromCurrentTransform() {
    final pages = _allStagePages;
    if (pages.isEmpty) return 0;
    final viewport = _overviewViewportSize();
    final matrix = _transformationController.value;
    final scale = matrix.storage[0]
        .clamp(_overviewPreviewScale, 1.0)
        .toDouble();
    final dx = matrix.storage[12];
    final viewportCenterX = viewport.width / 2;
    final contentCenterX = (viewportCenterX - dx) / scale;
    final cardWidth = _overviewCardSize().width;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < pages.length; i++) {
      final pageCenterX =
          _overviewCanvasInset +
          i * (cardWidth + _overviewPageGap) +
          cardWidth / 2;
      final distance = (pageCenterX - contentCenterX).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int _flatIndexForViewportPoint(Offset viewportPoint) {
    final pages = _allStagePages;
    if (pages.isEmpty) return 0;
    final matrix = _transformationController.value;
    final scale = matrix.storage[0]
        .clamp(_overviewPreviewScale, 1.0)
        .toDouble();
    final dx = matrix.storage[12];
    final dy = matrix.storage[13];
    final contentPoint = Offset(
      (viewportPoint.dx - dx) / scale,
      (viewportPoint.dy - dy) / scale,
    );
    for (var i = 0; i < pages.length; i++) {
      if (_overviewCardRect(pages[i]).contains(contentPoint)) {
        return i;
      }
    }
    return _nearestFlatIndexFromCurrentTransform();
  }

  Future<void> _handleOverviewCardTap(_StagePageReference page) async {
    final flatIndex = _allStagePages.indexWhere(
      (item) =>
          item.rakaatIndex == page.rakaatIndex &&
          item.stepIndex == page.stepIndex,
    );
    if (flatIndex < 0) return;
    setState(() => _overviewSelectedFlatIndex = flatIndex);
    await _closeOverviewMode(applySelection: true);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleGestureTriggered = false;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_showOverviewLayer ||
        _isStageTransitioning ||
        details.pointerCount < 2 ||
        _scaleGestureTriggered) {
      return;
    }
    if (details.scale <= _overviewOpenScaleThreshold) {
      _scaleGestureTriggered = true;
      unawaited(_openOverviewMode());
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _scaleGestureTriggered = false;
  }

  _DisplayedStepProgress _displayStepProgressFor({
    required int rakaatIndex,
    required int stepIndex,
  }) {
    if (_rakaats.isEmpty) {
      return const _DisplayedStepProgress(current: 1, total: 1);
    }
    final orderIndexes = _stepOrderIndexesForRakaatIndex(rakaatIndex);
    if (orderIndexes.isEmpty) {
      return const _DisplayedStepProgress(current: 1, total: 1);
    }
    final clampedStep = stepIndex.clamp(0, orderIndexes.length - 1);
    final currentOrderIndex = orderIndexes[clampedStep];
    final isFajr = widget.prayerCode.trim().toLowerCase() == 'fajr';
    final rakaatNumber =
        _rakaats[rakaatIndex.clamp(0, _rakaats.length - 1)].number;
    if (isFajr && rakaatNumber == 1) {
      if (currentOrderIndex <= 2) {
        return _DisplayedStepProgress(current: currentOrderIndex, total: 2);
      }
      return _DisplayedStepProgress(
        current: (currentOrderIndex - 2).clamp(1, 14),
        total: 14,
      );
    }
    return _DisplayedStepProgress(
      current: clampedStep + 1,
      total: orderIndexes.length,
    );
  }

  static const Map<String, String> _namazStepImageBaseNameByCode = {
    'takbir': 'takbir',
    'allahu_akbar': 'takbir',
    'ruku': 'ruku',
    'qiyam': 'stay',
    'standing': 'stay',
    'straightening': 'stay',
    'qawmah': 'stay',
    'istiadha': 'stay',
    'fatiha': 'stay',
    'al_fatiha': 'stay',
    'amin': 'stay',
    'additional_surah': 'stay',
    'sujud': 'sudjud',
    'sajda': 'sudjud',
    'jalsa': 'seat',
    'sitting': 'seat',
    'qaada': 'seat',
    'tashahhud': 'at-tahiyat',
    'at_tahiyat': 'at-tahiyat',
    'at-tahiyat': 'at-tahiyat',
    'taslim_left': 'taslim-left',
    'taslim_right': 'taslim-right',
    'taslim-left': 'taslim-left',
    'taslim-right': 'taslim-right',
  };

  String? _stepImageBaseNameFromText(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized.contains('taslim-right') ||
        normalized.contains('taslim right') ||
        normalized.contains('поверните голову направо')) {
      return 'taslim-right';
    }
    if (normalized.contains('taslim-left') ||
        normalized.contains('taslim left') ||
        normalized.contains('поверните голову налево')) {
      return 'taslim-left';
    }
    if (normalized.contains('at-tahiyat') ||
        normalized.contains('attahiyat') ||
        normalized.contains('tashahhud') ||
        normalized.contains('тахият') ||
        normalized.contains('ташаххуд')) {
      return 'at-tahiyat';
    }
    if (normalized.contains('takbir') ||
        normalized.contains('такбир') ||
        normalized.contains('аллах велик')) {
      return 'takbir';
    }
    if (normalized.contains('ruku') ||
        normalized.contains('руку') ||
        normalized.contains('поясной поклон')) {
      return 'ruku';
    }
    if (normalized.contains('sujud') ||
        normalized.contains('sudjud') ||
        normalized.contains('sajda') ||
        normalized.contains('суджуд') ||
        normalized.contains('саджда') ||
        normalized.contains('земной поклон')) {
      return 'sudjud';
    }
    if (normalized.contains('sitting') ||
        normalized.contains('jalsa') ||
        normalized.contains('qaada') ||
        normalized.contains('сидя') ||
        normalized.contains('положение сидя')) {
      return 'seat';
    }
    if (normalized.contains('standing') ||
        normalized.contains('qiyam') ||
        normalized.contains('straightening') ||
        normalized.contains('qawmah') ||
        normalized.contains('стоя') ||
        normalized.contains('выпрямление') ||
        normalized.contains('чтение') ||
        normalized.contains('reading') ||
        normalized.contains('мольба о защите')) {
      return 'stay';
    }
    return null;
  }

  String _stepImageAssetFor({
    required String explicitImageAsset,
    required String stepCode,
    required String title,
    required String movementDescription,
    required String fallbackAsset,
  }) {
    final normalizedExplicit = explicitImageAsset.trim();
    if (normalizedExplicit.isNotEmpty) return normalizedExplicit;
    final normalized = stepCode.trim().toLowerCase();
    final baseName =
        _namazStepImageBaseNameByCode[normalized] ??
        _stepImageBaseNameFromText(title) ??
        _stepImageBaseNameFromText(movementDescription) ??
        _stepImageBaseNameFromText(fallbackAsset) ??
        'stay';
    final genderCode = GenderRepositoryMemory.instance
        .getSelectedGender()
        .id
        .trim()
        .toLowerCase();
    final normalizedGender = genderCode == 'female' ? 'female' : 'male';
    return 'assets/namaz/images/$baseName'
        '_$normalizedGender.svg';
  }

  Widget _buildStepImage({
    required String stepImageAsset,
    required String fallbackStepImageAsset,
  }) {
    if (stepImageAsset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        stepImageAsset,
        width: 250.h,
        fit: BoxFit.none,
        theme: SvgTheme(currentColor: context.colors.textPrimary),
        placeholderBuilder: (context) => SizedBox(width: 250.h),
      );
    }
    return Image.asset(
      stepImageAsset,
      width: 250.h,
      errorBuilder: (context, error, stack) =>
          Image.asset(fallbackStepImageAsset, height: 250.h),
    );
  }

  Widget _buildOverviewPage({
    required _StagePageReference page,
    required String prayerTitle,
    required double cardTextSize,
  }) {
    final totalRakaats = _rakaats.isEmpty ? 2 : _rakaats.length;
    final rakaatIndex = page.rakaatIndex.clamp(0, _rakaats.length - 1);
    final orderIndexes = _stepOrderIndexesForRakaatIndex(rakaatIndex);
    final stepIndex = page.stepIndex.clamp(0, orderIndexes.length - 1);
    final displayProgress = _displayStepProgressFor(
      rakaatIndex: rakaatIndex,
      stepIndex: stepIndex,
    );
    final stepEntries = _entriesForPage(
      rakaatIndex: rakaatIndex,
      stepIndex: stepIndex,
    );
    final recitationEntries = _recitationEntriesForPage(
      rakaatIndex: rakaatIndex,
      stepIndex: stepIndex,
    );
    final step = stepEntries.firstOrNull;
    final title = (step?.title ?? '').trim().isEmpty
        ? context.t('stage.defaultStepTitle')
        : step!.title;
    final movementDescription = (step?.movementDescription ?? '').trim();
    final fallbackStepImageAsset = _rakaats[rakaatIndex].imageAsset.isEmpty
        ? 'assets/icons/salat.png'
        : _rakaats[rakaatIndex].imageAsset;
    final stepImageAsset = _stepImageAssetFor(
      explicitImageAsset: step?.imageAsset ?? '',
      stepCode: step?.stepCode ?? '',
      title: title,
      movementDescription: movementDescription,
      fallbackAsset: fallbackStepImageAsset,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 21.h,
          bottom: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Карточка занимает ровно столько места, сколько нужно
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StageProgressBlock(
              title: context.t(
                'stage.prayerTitleWithRakaats',
                namedArgs: {
                  'title': prayerTitle,
                  'count': '$totalRakaats',
                },
              ),
              rakaatIndex: rakaatIndex + 1,
              totalRakaats: totalRakaats,
              stepIndex: displayProgress.current,
              totalSteps: displayProgress.total,
              progress: displayProgress.total == 0
                  ? 0
                  : displayProgress.current / displayProgress.total,
              animateProgress: false,
            ),
            SizedBox(height: 12.h),
            StageCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 260.h,
                    decoration: BoxDecoration(
                      color: context.colors.soft,
                      borderRadius: BorderRadius.circular(AppRadii.inner.r),
                    ),
                    child: Center(
                      child: _buildStepImage(
                        stepImageAsset: stepImageAsset,
                        fallbackStepImageAsset: fallbackStepImageAsset,
                      ),
                    ),
                  ),
                  SizedBox(height: 25.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: cardTextSize.sp,
                          height: 1.48,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      if (movementDescription.isNotEmpty)
                        Text(
                          movementDescription,
                          style: TextStyle(
                            fontSize: cardTextSize.sp,
                            height: 1.48,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (recitationEntries.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (var i = 0; i < recitationEntries.length; i++) ...[
                    StageAyahCard(
                      ayahIndex: i,
                      ayah: recitationEntries[i],
                      textSize: cardTextSize,
                      selected: false,
                      isPlaying: false,
                      progress: 0,
                      onTap: () {},
                      onPlayPause: () {},
                    ),
                    if (i != recitationEntries.length - 1)
                      SizedBox(height: 16.h),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewLayer({
    required String prayerTitle,
    required double cardTextSize,
  }) {
    final pages = _allStagePages;
    final cardSize = _overviewCardSize();
    final canvasSize = _overviewCanvasSize();
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: context.colors.background,
      child: InteractiveViewer(
        transformationController: _transformationController,
        onInteractionStart: _handleOverviewInteractionStart,
        onInteractionUpdate: _handleOverviewPanUpdate,
        onInteractionEnd: _handleOverviewInteractionEnd,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        constrained: false,
        panEnabled: !_overviewGestureLock,
        scaleEnabled: !_overviewGestureLock,
        panAxis: PanAxis.horizontal, // ВЕРНУЛИ БЛОКИРОВКУ: только горизонтальный свайп
        interactionEndFrictionCoefficient: _overviewDragFriction,
        minScale: _overviewPreviewScale,
        maxScale: 1,
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            clipBehavior: Clip.none, // ДОБАВЛЕНО: позволяет карточкам выходить за нижнюю границу холста
            children: [
              for (final page in pages)
                () {
                  final position = _getCardPosition(
                    page.rakaatIndex,
                    page.stepIndex,
                  );
                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    width: cardSize.width,
                    // УДАЛЕНО: height: cardSize.height, (карточка сама определяет свою высоту)
                    child: RepaintBoundary(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => unawaited(_handleOverviewCardTap(page)),
                        child: IgnorePointer(
                          ignoring: true,
                          child: _buildOverviewPage(
                            page: page,
                            prayerTitle: prayerTitle,
                            cardTextSize: cardTextSize,
                            // УДАЛЕНО: pageHeight: pageHeight,
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _animateAppear(Widget child) {
    return AnimatedOpacity(
      opacity: _contentAppeared ? 1 : 0,
      duration: const Duration(milliseconds: 960),
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _animateRakaat(Widget child) {
    return child;
  }

  Widget _animateStepTransition(Widget child) {
    return child;
  }

  Future<void> _nextStep() async {
    if (_currentStepOrderIndexes.isEmpty || _isStageTransitioning) return;
    _triggerLightHaptic();
    if (_clampedStepIndex < _currentStepOrderIndexes.length - 1) {
      await _animateStepTransitionTo(_clampedStepIndex + 1, direction: 1);
      return;
    }
    if (_rakaats.isEmpty) return;
    final next = (_rakaatIndex + 1).clamp(0, _rakaats.length - 1);
    if (next == _rakaatIndex) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('stage.prayerCompleted'))),
      );
      return;
    }
    await _animateRakaatTransitionTo(next, stepIndex: 0, direction: 1);
  }

  Future<void> _popToHome() async {
    if (!mounted) return;
    setState(() => _allowExitPop = true);
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      setState(() => _allowExitPop = false);
    }
  }

  Future<void> _animateStepTransitionTo(
    int stepIndex, {
    required int direction,
  }) async {
    if (_currentStepOrderIndexes.isEmpty) return;
    final nextStep = stepIndex.clamp(0, _currentStepOrderIndexes.length - 1);
    await _selectRakaatAndStep(
      _rakaatIndex,
      nextStep,
      playIfAutoplay: false,
      direction: direction,
    );
  }

  Future<void> _animateRakaatTransitionTo(
    int index, {
    required int stepIndex,
    required int direction,
  }) async {
    await _selectRakaatAndStep(
      index,
      stepIndex,
      playIfAutoplay: false,
      direction: direction,
    );
  }

  Future<void> _prevStep() async {
    if (_currentStepOrderIndexes.isEmpty || _isStageTransitioning) return;
    _triggerLightHaptic();
    if (_clampedStepIndex > 0) {
      await _animateStepTransitionTo(_clampedStepIndex - 1, direction: -1);
      return;
    }
    if (_rakaats.isEmpty) return;
    final prev = (_rakaatIndex - 1).clamp(0, _rakaats.length - 1);
    if (prev == _rakaatIndex) return;
    final prevStepCount = _stepCountForRakaat(prev);
    final prevStepIndex = prevStepCount == 0 ? 0 : prevStepCount - 1;
    await _animateRakaatTransitionTo(
      prev,
      stepIndex: prevStepIndex,
      direction: -1,
    );
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isOverviewMode) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_horizontalSwipeVelocityThreshold) {
      unawaited(_nextStep());
      return;
    }
    if (velocity >= _horizontalSwipeVelocityThreshold) {
      unawaited(_prevStep());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardTextSize = ThemeTextSizeStore.textSize;
    final totalRakaats = _rakaats.isEmpty ? 2 : _rakaats.length;
    final rakaatIndex = (_rakaats.isEmpty ? 0 : _rakaatIndex) + 1;
    final rawStepIndex = _currentStepOrderIndexes.isEmpty
        ? 0
        : _clampedStepIndex;
    final displayProgress = _displayStepProgressFor(
      rakaatIndex: _rakaatIndex.clamp(0, _rakaats.length - 1),
      stepIndex: rawStepIndex,
    );
    final totalSteps = displayProgress.total;
    final stepIndex = displayProgress.current;
    final stepProgress = totalSteps == 0 ? 0.0 : (stepIndex / totalSteps);
    final audioProgress = _audio.progress;
    final currentStep = _currentStep;
    final prayerTitle = localizedPrayerLabel(
      context,
      widget.prayerCode,
      fallbackTitle: widget.prayerTitle.trim().isEmpty
          ? context.t('stage.prayerDefaultTitle')
          : widget.prayerTitle,
    );
    final stepTitle = (currentStep?.title ?? '').trim().isEmpty
        ? context.t('stage.defaultStepTitle')
        : currentStep!.title;
    final movementDescription = (currentStep?.movementDescription ?? '').trim();
    final fallbackStepImageAsset =
        _currentRakaat?.imageAsset ?? 'assets/icons/salat.png';
    final currentStepCode = (currentStep?.stepCode ?? '');
    final currentStepImageAsset = _stepImageAssetFor(
      explicitImageAsset: (currentStep?.imageAsset ?? ''),
      stepCode: currentStepCode,
      title: stepTitle,
      movementDescription: movementDescription,
      fallbackAsset: fallbackStepImageAsset,
    );
    final additionalSurahOptions = _additionalSurahOptions;
    final hasAdditionalSurahSelector =
        additionalSurahOptions.isNotEmpty &&
        _isAdditionalSurahStep(currentStep);
    final selectedAdditionalSurahIndex = _selectedAdditionalSurahIndex(
      additionalSurahOptions,
    );
    final currentStepEntries = _currentRecitationEntries;
    final selectedAyahCardKey = _stepKeys.putIfAbsent(
      _entryKey(_clampedAyahIndex),
      () => GlobalKey(),
    );
    final hasPrevStageStep = _hasPrevStageStep;
    final hasNextStageStep = _hasNextStageStep;
    final canGoBack = hasPrevStageStep;
    final canGoNext = hasNextStageStep;
    final navButtonsVisible = !_showOverviewLayer && !_isOverviewClosing;
    final restingTopInset = _overviewRestingTopInset();
    final topControlInset = restingTopInset;
    final topContentPadding = topControlInset;
    const pinnedHideDuration = Duration(milliseconds: 260);
    const pinnedFadeDuration = Duration(milliseconds: 220);

    return PopScope(
      canPop: _allowExitPop,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _showOverviewLayer
                ? null
                : _handleHorizontalDragEnd,
            onScaleStart: _showOverviewLayer ? null : _onScaleStart,
            onScaleUpdate: _showOverviewLayer ? null : _onScaleUpdate,
            onScaleEnd: _showOverviewLayer ? null : _onScaleEnd,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IgnorePointer(
                      ignoring: _showOverviewLayer,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          padding: EdgeInsets.only(
                            bottom: 34.h,
                            top: topContentPadding,
                          ),
                          child: _animateStepTransition(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                              IgnorePointer(
                                ignoring: !_showTopControls,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  scale: _showTopControls ? 1 : 0.9,
                                  alignment: Alignment.center,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    opacity: _showTopControls ? 1 : 0,
                                    child: StageTopBar(
                                      onBack: () => unawaited(_popToHome()),
                                      onStage: _showStageSheet,
                                      stageButtonKey: _stageButtonKey,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              _animateAppear(
                                Pressable(
                                  onTap: _openOverviewMode,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.card.r,
                                  ),
                                  child: KeyedSubtree(
                                    key: _progressKey,
                                    child: StageProgressBlock(
                                      title: context.t(
                                        'stage.prayerTitleWithRakaats',
                                        namedArgs: {
                                          'title': prayerTitle,
                                          'count': '$totalRakaats',
                                        },
                                      ),
                                      rakaatIndex: rakaatIndex,
                                      totalRakaats: totalRakaats,
                                      stepIndex: stepIndex,
                                      totalSteps: totalSteps,
                                      progress: stepProgress.clamp(0.0, 1.0),
                                      animateProgress: false,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _animateRakaat(
                                _animateAppear(
                                  StageCard(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 260.h,
                                          decoration: BoxDecoration(
                                            color: colors.soft,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.inner.r,
                                            ),
                                          ),
                                          child: Center(
                                            child: _buildStepImage(
                                              stepImageAsset:
                                                  currentStepImageAsset,
                                              fallbackStepImageAsset:
                                                  fallbackStepImageAsset,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 25.h),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              stepTitle,
                                              style: TextStyle(
                                                fontSize: cardTextSize.sp,
                                                height: 1.48,
                                                fontWeight: FontWeight.w500,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 10.h),
                                            if (movementDescription.isNotEmpty)
                                              Text(
                                                movementDescription,
                                                style: TextStyle(
                                                  fontSize: cardTextSize.sp,
                                                  height: 1.48,
                                                  fontWeight: FontWeight.w500,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              if (hasAdditionalSurahSelector) ...[
                                _animateAppear(
                                  StageSurahSelector(
                                    labels: additionalSurahOptions
                                        .map((option) => option.label)
                                        .toList(growable: false),
                                    selectedIndex: selectedAdditionalSurahIndex,
                                    onSelect: (optionIndex) =>
                                        _onSelectAdditionalSurah(
                                          options: additionalSurahOptions,
                                          optionIndex: optionIndex,
                                        ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                              ],
                              _animateRakaat(
                                _animateAppear(
                                  Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < currentStepEntries.length;
                                        i++
                                      ) ...[
                                        () {
                                          final entryKey = _entryKey(i);
                                          final isSelected =
                                              _playingStepKey == entryKey;
                                          final isEntryPlaying =
                                              isSelected && _audio.isPlaying;
                                          return KeyedSubtree(
                                            key: _stepKeys.putIfAbsent(
                                              entryKey,
                                              () => GlobalKey(),
                                            ),
                                            child: StageAyahCard(
                                              ayahIndex: i,
                                              ayah: currentStepEntries[i],
                                              textSize: cardTextSize,
                                              selected: isSelected,
                                              isPlaying: isEntryPlaying,
                                              progress: isSelected
                                                  ? audioProgress.clamp(0.0, 1.0)
                                                  : 0.0,
                                              onTap: () {
                                                _triggerLightHaptic();
                                                if (i == _clampedAyahIndex) {
                                                  _togglePlay();
                                                } else {
                                                  _playStepAt(i);
                                                }
                                              },
                                              onPlayPause: () {
                                                _triggerLightHaptic();
                                                if (i == _clampedAyahIndex) {
                                                  _togglePlay();
                                                } else {
                                                  _playStepAt(i);
                                                }
                                              },
                                            ),
                                          );
                                        }(),
                                        if (i != currentStepEntries.length - 1)
                                          SizedBox(height: 16.h),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                SizedBox(height: 12.h),
                                StageCard(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 20.h),
                              IgnorePointer(
                                ignoring: !navButtonsVisible,
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  offset: navButtonsVisible
                                      ? Offset.zero
                                      : const Offset(0, 0.06),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    opacity: navButtonsVisible ? 1 : 0,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            opacity: hasPrevStageStep ? 1 : 0.5,
                                            child: StageBottomButton(
                                              variant: StageBottomButtonVariant
                                                  .secondary,
                                              label: context.t('common.back'),
                                              icon: 'assets/icons/arrow-left.svg',
                                              onTap: canGoBack ? _prevStep : null,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          flex: 4,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            opacity: hasNextStageStep ? 1 : 0.5,
                                            child: StageBottomButton(
                                              variant: StageBottomButtonVariant
                                                  .primary,
                                              label: context.t('common.next'),
                                              icon:
                                                  'assets/icons/arrow-right.svg',
                                              onTap: canGoNext ? _nextStep : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_showOverviewLayer)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: _isOverviewClosing,
                          child: _buildOverviewLayer(
                            prayerTitle: prayerTitle,
                            cardTextSize: cardTextSize,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!_showOverviewLayer && _showTopBlur && !_isOverviewMode)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: true,
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).top + 110.h,
                        child: const AppBlurredTopOverlay(
                          visible: true,
                          height: 120,
                          maxBlurSigma: 52,
                          child: SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                if (!_showOverviewLayer)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    top: MediaQuery.paddingOf(context).top + 12.h,
                    child: IgnorePointer(
                      ignoring: !_showPinned || _isOverviewMode,
                      child: AnimatedSlide(
                        offset: _showPinned
                            ? Offset.zero
                            : const Offset(0, -0.35),
                        duration: pinnedHideDuration,
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          duration: pinnedFadeDuration,
                          curve: Curves.easeOutCubic,
                          opacity: _showPinned ? 1 : 0,
                          child: Pressable(
                            onTap: _openOverviewMode,
                            borderRadius: BorderRadius.circular(
                              AppRadii.card.r,
                            ),
                            child: StagePinnedProgressCard(
                              rakaatIndex: rakaatIndex,
                              totalRakaats: totalRakaats,
                              stepIndex: stepIndex,
                              totalSteps: totalSteps,
                              progress: stepProgress.clamp(0.0, 1.0),
                              animateProgress: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_showOverviewExitButton)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    bottom: MediaQuery.paddingOf(context).bottom + 24.h,
                    child: IgnorePointer(
                      ignoring: false,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: Offset.zero,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          opacity: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadii.inner.r,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.08
                                        : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AppButton(
                              label: context.t('common.exit'),
                              onPressed: () => unawaited(_closeOverviewMode()),
                              variant: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppButtonVariant.card
                                  : AppButtonVariant.secondary,
                              size: AppButtonSize.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isOverviewClosing && _showTopControls)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    top: topControlInset,
                    child: IgnorePointer(
                      ignoring: true,
                      child: StageTopBar(onBack: () {}, onStage: () {}),
                    ),
                  ),
                if (_showOnboarding && !_showOverviewLayer)
                  Positioned.fill(
                    key: const ValueKey('stage_onboarding_overlay'),
                    child: IgnorePointer(
                      ignoring: false,
                      child: StageOnboardingOverlay(
                        key: const ValueKey('stage_onboarding_overlay_content'),
                        stageButtonKey: _stageButtonKey,
                        progressCardKey: _progressKey,
                        selectedAyahCardKey: selectedAyahCardKey,
                        scrollController: _scrollController,
                        stepIndex: _onboardingStepIndex,
                        onNext: _onOnboardingNext,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStageSheet() async {
    if (_rakaats.isEmpty) return;
    _triggerLightHaptic();
    var selectedRakaat = _rakaatIndex.clamp(0, _rakaats.length - 1);

    final selected = await showModalBottomSheet<_StageSectionSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final steps = _groupedStepsForRakaat(selectedRakaat);
            return SafeArea(
              top: false,
              bottom: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 10.h),
                height: MediaQuery.sizeOf(context).height * 0.9,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(28.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.t('stage.selectSection'),
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Pressable(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(AppRadii.circle),
                          child: Container(
                            width: 24.r,
                            height: 24.r,
                            decoration: BoxDecoration(
                              color: colors.soft,
                              borderRadius: BorderRadius.circular(
                                AppRadii.circle,
                              ),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/close-icon.svg',
                              width: 24.r,
                              height: 24.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: BorderRadius.circular(AppRadii.pill.r),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < _rakaats.length; i++)
                            Expanded(
                              child: Pressable(
                                onTap: () {
                                  _triggerLightHaptic();
                                  setModalState(() => selectedRakaat = i);
                                },
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: i == selectedRakaat
                                        ? colors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                  ),
                                  child: Text(
                                    context.t(
                                      'stage.rakaatLabel',
                                      namedArgs: {'count': '${i + 1}'},
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: i == selectedRakaat
                                          ? Colors.white
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: steps.length,
                        separatorBuilder: (context, index) =>
                            Container(height: 1, color: colors.divider),
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          return Pressable(
                            onTap: () {
                              _triggerLightHaptic();
                              Navigator.of(context).pop(
                                _StageSectionSelection(selectedRakaat, index),
                              );
                            },
                            borderRadius: BorderRadius.circular(AppRadii.inner),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 20.h,
                                horizontal: 2.w,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      step.title,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        height: 1.36,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  SvgPicture.asset(
                                    'assets/icons/arrow-right-chevron.svg',
                                    width: 10.r,
                                    colorFilter: ColorFilter.mode(
                                      colors.textMuted,
                                      BlendMode.srcIn,
                                    ),
                                    fit: BoxFit.none,
                                  ),
                                  SizedBox(width: 7.w),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;
    await _jumpToRakaatAndStep(
      rakaatIndex: selected.rakaatIndex,
      stepIndex: selected.stepIndex,
    );
  }

  Future<void> _jumpToRakaatAndStep({
    required int rakaatIndex,
    required int stepIndex,
  }) async {
    if (_rakaats.isEmpty) return;
    final nextRakaat = rakaatIndex.clamp(0, _rakaats.length - 1);
    final steps = _groupedStepsForRakaat(nextRakaat);
    if (steps.isEmpty) return;
    final nextStep = stepIndex.clamp(0, steps.length - 1);
    final currentStepIndex = _clampedStepIndex;
    if (nextRakaat == _rakaatIndex && nextStep == currentStepIndex) {
      return;
    }
    if (nextRakaat == _rakaatIndex) {
      await _animateStepTransitionTo(
        nextStep,
        direction: nextStep >= currentStepIndex ? 1 : -1,
      );
      return;
    }
    await _animateRakaatTransitionTo(
      nextRakaat,
      stepIndex: nextStep,
      direction: nextRakaat >= _rakaatIndex ? 1 : -1,
    );
  }

  List<_StageStepGroup> _groupedStepsForRakaat(int rakaatIndex) {
    if (_rakaats.isEmpty) return const [];
    final index = rakaatIndex.clamp(0, _rakaats.length - 1);
    final byOrder = <int, RakaatStep>{};
    for (final step in _rakaats[index].steps) {
      byOrder.putIfAbsent(step.orderIndex, () => step);
    }
    final sorted = byOrder.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted
        .map((entry) => _StageStepGroup(title: entry.value.title))
        .toList(growable: false);
  }
}

class _StageSectionSelection {
  const _StageSectionSelection(this.rakaatIndex, this.stepIndex);

  final int rakaatIndex;
  final int stepIndex;
}

class _StagePageReference {
  const _StagePageReference({
    required this.rakaatIndex,
    required this.stepIndex,
  });

  final int rakaatIndex;
  final int stepIndex;
}

class _StageStepGroup {
  const _StageStepGroup({required this.title});

  final String title;
}

class _DisplayedStepProgress {
  const _DisplayedStepProgress({required this.current, required this.total});

  final int current;
  final int total;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
