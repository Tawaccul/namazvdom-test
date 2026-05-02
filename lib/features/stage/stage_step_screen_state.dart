import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/app_dependencies_scope.dart';
import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../core/audio/ayah_audio.dart';
import '../../core/audio/ayah_audio_controller.dart';
import '../../core/text/transliteration_localizer.dart';
import '../onboarding/data/onboarding_repository_memory.dart';
import '../prayer/domain/usecases/get_prayer_surah.dart';
import '../settings/gender/data/gender_repository_memory.dart';
import '../settings/language/data/language_repository_memory.dart';
import '../settings/theme/presentation/theme_text_size_store.dart';
import 'parts/stage_overview_page_builder.dart';
import 'parts/stage_additional_surah_helper.dart';
import 'parts/stage_audio_playback_helper.dart';
import 'parts/stage_step_data_helper.dart';
import 'parts/stage_overview_state_helper.dart';
import 'parts/stage_step_screen_builder.dart';
import 'parts/stage_step_screen_flow_helper.dart';
import 'parts/stage_section_sheet.dart';
import 'parts/stage_step_image.dart';
import 'models/rakaat_models.dart';
import 'models/stage_step_screen_models.dart';
import '../quran/model/quran_ayah.dart';
import 'stage_prayer_loader.dart';
import 'stage_overview_geometry.dart';

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
  static const double _overviewPreviewScale = 0.50;
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
  int _additionalSurahAnimationToken = 0;
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

  bool _isAdditionalSurahStep(RakaatStep? step) =>
      StageAdditionalSurahHelper.isAdditionalSurahStep(step);

  int _selectedAdditionalSurahIndex(List<RakaatSurahOption> options) {
    return _selectedAdditionalSurahIndexForStep(options, _currentStep);
  }

  int _selectedAdditionalSurahIndexForStep(
    List<RakaatSurahOption> options,
    RakaatStep? step,
  ) => StageAdditionalSurahHelper.selectedIndexForStep(
    options: options,
    selectedAdditionalSurahCode: _selectedAdditionalSurahCode,
    step: step,
  );

  Future<void> _onSelectAdditionalSurah({
    required List<RakaatSurahOption> options,
    required int optionIndex,
  }) async {
    if (optionIndex < 0 || optionIndex >= options.length) return;
    final option = options[optionIndex];
    setState(() => _selectedAdditionalSurahCode = option.code);
    try {
      final result =
          await StageAdditionalSurahHelper.replaceAdditionalSurahSteps(
            context: context,
            rakaats: _rakaats,
            rakaatIndex: _rakaatIndex,
            option: option,
            forceLocalOnly: StagePrayerLoader.forceLocalOnly,
            assetExistsMemo: _assetExistsMemo,
            translateKey: _translateKey,
            loadRemoteSteps: _loadRemoteAdditionalSurahSteps,
          );
      if (result == null || !mounted) return;
      setState(() {
        _rakaats = result.updatedRakaats;
        _additionalSurahAnimationToken++;
      });
      _autoplayEnabled = false;
      await _selectStep(
        result.targetStepIndex,
        playIfAutoplay: false,
        animateStepTransition: false,
        jumpToTop: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<List<RakaatStep>> _loadRemoteAdditionalSurahSteps({
    required String surahCode,
    required String title,
    required int orderIndex,
    required String audioUrl,
  }) async {
    final repository = AppDependenciesScope.prayerRepositoryOf(context);
    final getPrayerSurah = GetPrayerSurah(repository);
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    final surah = await getPrayerSurah(
      surahCode: surahCode,
      languageCode: languageCode,
    );
    return surah.ayahs
        .map(
          (ayah) => RakaatStep(
            orderIndex: orderIndex,
            title: title,
            movementDescription: '',
            arabic: ayah.recitationArabic,
            transliteration: localizedTransliteration(
              ayah.transliteration,
              languageCode,
            ),
            translation: ayah.translation,
            stepCode: 'additional_surah',
            audioUrl: audioUrl,
            surahCode: surahCode,
            additionalSurahOptionCode: surahCode,
          ),
        )
        .toList(growable: false);
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
    _transformationController.removeListener(_handleOverviewTransformChanged);
    _overviewAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
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
    return StageStepDataHelper.stepCountForRakaat(
      rakaats: _rakaats,
      rakaatIndex: rakaatIndex,
    );
  }

  bool get _hasNextStageStep {
    return StageStepDataHelper.hasNextStageStep(
      currentStepOrderIndexes: _currentStepOrderIndexes,
      clampedStepIndex: _clampedStepIndex,
      rakaats: _rakaats,
      rakaatIndex: _rakaatIndex,
    );
  }

  bool get _hasPrevStageStep {
    return StageStepDataHelper.hasPrevStageStep(
      currentStepOrderIndexes: _currentStepOrderIndexes,
      clampedStepIndex: _clampedStepIndex,
      rakaats: _rakaats,
      rakaatIndex: _rakaatIndex,
    );
  }

  List<int> get _currentStepOrderIndexes =>
      StageStepDataHelper.currentStepOrderIndexes(
        currentRakaatSteps: _currentRakaatSteps,
      );

  int get _clampedStepIndex {
    if (_currentStepOrderIndexes.isEmpty) return 0;
    return _stepIndex.clamp(0, _currentStepOrderIndexes.length - 1);
  }

  int? get _currentStepOrderIndex => _currentStepOrderIndexes.isEmpty
      ? null
      : _currentStepOrderIndexes[_clampedStepIndex];

  List<RakaatStep> get _currentStepEntries =>
      StageStepDataHelper.currentStepEntries(
        currentRakaatSteps: _currentRakaatSteps,
        currentStepOrderIndex: _currentStepOrderIndex,
      );

  RakaatStep? get _currentStep => _currentStepEntries.firstOrNull;

  List<RakaatStep> get _currentRecitationEntries =>
      StageStepDataHelper.currentRecitationEntries(
        currentStepEntries: _currentStepEntries,
      );

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
    return StageAudioPlaybackHelper.waitForPlaybackCompletion(
      audio: _audio,
      sessionId: sessionId,
      stepKey: stepKey,
      isAutoplaySessionActive: _isAutoplaySessionActive,
      getPlayingStepKey: () => _playingStepKey,
      setStartedPlaybackStepKey: (value) => _startedPlaybackStepKey = value,
      getStartedPlaybackStepKey: () => _startedPlaybackStepKey,
    );
  }

  Future<void> _startPageAutoplayFrom(int ayahIndex) =>
      StageAudioPlaybackHelper.startPageAutoplayFrom(
        ayahIndex: ayahIndex,
        currentRecitationEntries: _currentRecitationEntries,
        cancelAutoplaySequence: _cancelAutoplaySequence,
        setAutoplayEnabled: (value) => _autoplayEnabled = value,
        getAutoplaySessionId: () => _autoplaySessionId,
        isAutoplaySessionActive: _isAutoplaySessionActive,
        selectAyahInCurrentStep: _selectAyahInCurrentStep,
        getStepKey: () => _stepKey,
        playCurrent: _playCurrent,
        waitForPlaybackCompletion: _waitForPlaybackCompletion,
        dismissFloatingPlayer: _dismissFloatingPlayer,
        setError: (message) => setState(() => _error = message),
        mounted: mounted,
      );

  QuranAyah _stepToAyah(RakaatStep step, String id) =>
      StageAudioPlaybackHelper.stepToAyah(
        step: step,
        id: id,
        audioUrlForEntry: _audioUrlForEntry,
      );

  Future<void> _togglePlay() => StageAudioPlaybackHelper.togglePlay(
    audio: _audio,
    selectedAyahStep: _selectedAyahStep,
    stepKey: _stepKey,
    playingStepKey: _playingStepKey,
    mounted: mounted,
    currentRecitationEntries: _currentRecitationEntries,
    startPageAutoplayFromCurrentAyah: () =>
        _startPageAutoplayFrom(_clampedAyahIndex),
    setAyah: _audio.setAyah,
    stepToAyah: _stepToAyah,
    playCurrent: _playCurrent,
    notifyUi: () => setState(() {}),
    setError: (message) => setState(() => _error = message),
  );

  Future<void> _playCurrent() => StageAudioPlaybackHelper.playCurrent(
    audio: _audio,
    selectedAyahStep: _selectedAyahStep,
    mounted: mounted,
    stepKey: _stepKey,
    setPlayingStepKey: (value) => _playingStepKey = value,
    setStartedPlaybackStepKey: (value) => _startedPlaybackStepKey = value,
    notifyUi: () => setState(() {}),
  );

  Future<void> _dismissFloatingPlayer() =>
      StageAudioPlaybackHelper.dismissFloatingPlayer(
        audio: _audio,
        mounted: mounted,
        cancelAutoplaySequence: _cancelAutoplaySequence,
        setPlayingStepKey: (value) => _playingStepKey = value,
        setStartedPlaybackStepKey: (value) => _startedPlaybackStepKey = value,
        notifyUi: () => setState(() {}),
      );

  Future<void> _playStepAt(int ayahIndex) async {
    if (_currentRecitationEntries.isEmpty) return;
    await _startPageAutoplayFrom(ayahIndex);
  }

  Future<void> _selectAyahInCurrentStep(
    int ayahIndex, {
    bool playIfAutoplay = true,
  }) => StageAudioPlaybackHelper.selectAyahInCurrentStep(
    ayahIndex: ayahIndex,
    playIfAutoplay: playIfAutoplay,
    currentRecitationEntries: _currentRecitationEntries,
    setSelectedAyahIndex: (next) => setState(() => _selectedAyahIndex = next),
    getSelectedAyahStep: () => _selectedAyahStep,
    getStepKey: () => _stepKey,
    isAutoplayEnabled: () => _autoplayEnabled,
    setAyah: _audio.setAyah,
    stepToAyah: _stepToAyah,
    setPlayingStepKey: (value) => _playingStepKey = value,
    setStartedPlaybackStepKey: (value) => _startedPlaybackStepKey = value,
    playCurrent: _playCurrent,
  );

  Future<void> _selectStep(
    int index, {
    bool playIfAutoplay = true,
    int direction = 1,
    bool animateStepTransition = true,
    bool jumpToTop = true,
  }) async {
    if (_currentStepOrderIndexes.isEmpty) return;
    final next = index.clamp(0, _currentStepOrderIndexes.length - 1);
    await _selectRakaatAndStep(
      _rakaatIndex,
      next,
      playIfAutoplay: playIfAutoplay,
      direction: direction,
      animateStepTransition: animateStepTransition,
      jumpToTop: jumpToTop,
    );
  }

  Future<void> _selectRakaatAndStep(
    int rakaatIndex,
    int stepIndex, {
    bool playIfAutoplay = false,
    int direction = 1,
    bool animateStepTransition = true,
    bool jumpToTop = true,
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
      if (jumpToTop) {
        _jumpToTop();
      }

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

  List<int> _stepOrderIndexesForRakaatIndex(int rakaatIndex) =>
      StageStepDataHelper.stepOrderIndexesForRakaatIndex(
        rakaats: _rakaats,
        rakaatIndex: rakaatIndex,
      );

  List<StagePageReference> get _allStagePages =>
      StageStepDataHelper.allStagePages(
        rakaats: _rakaats,
        stepOrderIndexesForRakaatIndex: _stepOrderIndexesForRakaatIndex,
      );

  int get _currentFlatPageIndex => StageStepDataHelper.currentFlatPageIndex(
    allStagePages: _allStagePages,
    rakaatIndex: _rakaatIndex,
    clampedStepIndex: _clampedStepIndex,
  );

  List<RakaatStep> _entriesForPage({
    required int rakaatIndex,
    required int stepIndex,
  }) => StageStepDataHelper.entriesForPage(
    rakaats: _rakaats,
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
    stepOrderIndexesForRakaatIndex: _stepOrderIndexesForRakaatIndex,
  );

  List<RakaatStep> _recitationEntriesForPage({
    required int rakaatIndex,
    required int stepIndex,
  }) => StageStepDataHelper.recitationEntriesForPage(
    rakaats: _rakaats,
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
    stepOrderIndexesForRakaatIndex: _stepOrderIndexesForRakaatIndex,
  );

  StageOverviewGeometry get _overviewGeometry => StageOverviewGeometry(
    pages: _allStagePages,
    previewScale: _overviewPreviewScale,
    pageGap: _overviewPageGap,
    canvasInset: _overviewCanvasInset,
    fitPadding: _overviewFitPadding,
    closingTopInset: _overviewClosingTopInset,
    previewTopShift: _overviewPreviewTopShift,
  );

  double _overviewRestingTopInset() =>
      _overviewGeometry.restingTopInset(context);

  Size _overviewCardSize() => _overviewGeometry.cardSize(context);

  Offset _getCardPosition(int rakaatIndex, int stepIndex) =>
      _overviewGeometry.cardPosition(context, rakaatIndex, stepIndex);

  Size _overviewCanvasSize() => _overviewGeometry.canvasSize(context);

  Matrix4 _overviewMatrixForPage(StagePageReference page, {double scale = 1}) =>
      _overviewGeometry.matrixForPage(context, page, scale: scale);

  void _setStateSafe(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _handleOverviewTransformChanged() =>
      StageOverviewStateHelper.handleOverviewTransformChanged(
        showOverviewLayer: _showOverviewLayer,
        isAnimatingOverviewMatrix: _isAnimatingOverviewMatrix,
        isClampingOverviewTransform: _isClampingOverviewTransform,
        clampOverviewTransform: _clampOverviewTransform,
        transformationController: _transformationController,
        matricesAreEqual: _matricesAreEqual,
        setIsClampingOverviewTransform: (value) =>
            _isClampingOverviewTransform = value,
      );

  void _handleOverviewPanUpdate(ScaleUpdateDetails details) =>
      StageOverviewStateHelper.handleOverviewPanUpdate(
        details: details,
        isAnimatingOverviewMatrix: _isAnimatingOverviewMatrix,
        isClampingOverviewTransform: _isClampingOverviewTransform,
        overviewGestureLock: _overviewGestureLock,
        overviewPinchCloseTriggered: _overviewPinchCloseTriggered,
        overviewSelectedFlatIndex: _overviewSelectedFlatIndex,
        overviewPendingCloseFlatIndex: _overviewPendingCloseFlatIndex,
        overviewPreviewScale: _overviewPreviewScale,
        overviewCloseScaleThreshold: _overviewCloseScaleThreshold,
        overviewPanSpeedMultiplier: _overviewPanSpeedMultiplier,
        mounted: mounted,
        transformationController: _transformationController,
        flatIndexForViewportPoint: _flatIndexForViewportPoint,
        nearestFlatIndexFromCurrentTransform:
            _nearestFlatIndexFromCurrentTransform,
        pageForFlatIndex: _pageForFlatIndex,
        overviewMatrixForPage: _overviewMatrixForPage,
        clampOverviewTransform: _clampOverviewTransform,
        closeOverviewFromPinch: _closeOverviewFromPinch,
        setOverviewSelectedFlatIndex: (value) =>
            _overviewSelectedFlatIndex = value,
        setOverviewPendingCloseFlatIndex: (value) =>
            _overviewPendingCloseFlatIndex = value,
        setOverviewPinchCloseTriggered: (value) =>
            _overviewPinchCloseTriggered = value,
        setOverviewGestureLock: (value) => _overviewGestureLock = value,
        setIsClampingOverviewTransform: (value) =>
            _isClampingOverviewTransform = value,
        setStateSafe: _setStateSafe,
      );

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

  Matrix4 _clampOverviewTransform(Matrix4 matrix) =>
      _overviewGeometry.clampTransform(context, matrix);

  bool _matricesAreEqual(Matrix4 a, Matrix4 b) =>
      _overviewGeometry.matricesAreEqual(a, b);

  Future<void> _animateOverviewMatrix(
    Matrix4 target, {
    Duration duration = _overviewMatrixDuration,
    Curve curve = Curves.easeOutCubic,
  }) => StageOverviewStateHelper.animateOverviewMatrix(
    mounted: mounted,
    overviewAnimationController: _overviewAnimationController,
    transformationController: _transformationController,
    target: target,
    duration: duration,
    curve: curve,
    setIsAnimatingOverviewMatrix: (value) => _isAnimatingOverviewMatrix = value,
  );

  Future<void> _openOverviewMode() => StageOverviewStateHelper.openOverviewMode(
    isOverviewMode: _isOverviewMode,
    showOverviewLayer: _showOverviewLayer,
    isAnimatingOverviewMatrix: _isAnimatingOverviewMatrix,
    isStageTransitioning: _isStageTransitioning,
    currentFlatPageIndex: _currentFlatPageIndex,
    pageForFlatIndex: _pageForFlatIndex,
    cancelAutoplaySequence: _cancelAutoplaySequence,
    pauseAudio: _audio.pause,
    mounted: mounted,
    transformationController: _transformationController,
    overviewMatrixForPage: _overviewMatrixForPage,
    overviewPreviewScale: _overviewPreviewScale,
    animateOverviewMatrix: _animateOverviewMatrix,
    setTopControlsRevealToken: (value) => _topControlsRevealToken = value,
    topControlsRevealToken: _topControlsRevealToken,
    setStateSafe: _setStateSafe,
    setOverviewOriginFlatIndex: (value) => _overviewOriginFlatIndex = value,
    setOverviewSelectedFlatIndex: (value) => _overviewSelectedFlatIndex = value,
    setOverviewPinchCloseTriggered: (value) =>
        _overviewPinchCloseTriggered = value,
    setOverviewGestureLock: (value) => _overviewGestureLock = value,
    setOverviewPendingCloseFlatIndex: (value) =>
        _overviewPendingCloseFlatIndex = value,
    setShowTopControls: (value) => _showTopControls = value,
    setShowOverviewLayer: (value) => _showOverviewLayer = value,
    setIsOverviewMode: (value) => _isOverviewMode = value,
    setIsOverviewClosing: (value) => _isOverviewClosing = value,
    setShowOverviewExitButton: (value) => _showOverviewExitButton = value,
    setShowPinned: (value) => _showPinned = value,
    clearAudioPlaybackKeys: () {
      _playingStepKey = null;
      _startedPlaybackStepKey = null;
    },
    isOverviewLayerShown: () => _showOverviewLayer,
  );

  Future<void> _closeOverviewMode({bool applySelection = false}) =>
      StageOverviewStateHelper.closeOverviewMode(
        showOverviewLayer: _showOverviewLayer,
        isAnimatingOverviewMatrix: _isAnimatingOverviewMatrix,
        applySelection: applySelection,
        overviewSelectedFlatIndex: _overviewSelectedFlatIndex,
        overviewOriginFlatIndex: _overviewOriginFlatIndex,
        pageForFlatIndex: _pageForFlatIndex,
        setScaleGestureTriggered: (value) => _scaleGestureTriggered = value,
        setOverviewPinchCloseTriggered: (value) =>
            _overviewPinchCloseTriggered = value,
        setOverviewPendingCloseFlatIndex: (value) =>
            _overviewPendingCloseFlatIndex = value,
        setStateSafe: _setStateSafe,
        setShowOverviewLayer: (value) => _showOverviewLayer = value,
        setIsOverviewMode: (value) => _isOverviewMode = value,
        setIsOverviewClosing: (value) => _isOverviewClosing = value,
        setShowOverviewExitButton: (value) => _showOverviewExitButton = value,
        setOverviewGestureLock: (value) => _overviewGestureLock = value,
        setShowPinned: (value) => _showPinned = value,
        scheduleTopControlsReveal: _scheduleTopControlsReveal,
        animateOverviewMatrix: _animateOverviewMatrix,
        overviewMatrixForPage: _overviewMatrixForPage,
        mounted: mounted,
        currentRakaatIndex: _rakaatIndex,
        clampedStepIndex: _clampedStepIndex,
        jumpToTop: _jumpToTop,
        selectRakaatAndStep: _selectRakaatAndStep,
      );

  void _scheduleTopControlsReveal() =>
      StageOverviewStateHelper.scheduleTopControlsReveal(
        nextToken: _topControlsRevealToken + 1,
        setTopControlsRevealToken: (value) => _topControlsRevealToken = value,
        mounted: () => mounted,
        topControlsRevealToken: () => _topControlsRevealToken,
        showOverviewLayer: () => _showOverviewLayer,
        showTopControls: () => _showTopControls,
        setStateSafe: _setStateSafe,
        setShowTopControls: (value) => _showTopControls = value,
      );

  StagePageReference? _pageForFlatIndex(int flatIndex) {
    final pages = _allStagePages;
    if (pages.isEmpty) return null;
    return pages[flatIndex.clamp(0, pages.length - 1)];
  }

  Future<void> _closeOverviewFromPinch() =>
      StageOverviewStateHelper.closeOverviewFromPinch(
        showOverviewLayer: _showOverviewLayer,
        isAnimatingOverviewMatrix: _isAnimatingOverviewMatrix,
        overviewPendingCloseFlatIndex: _overviewPendingCloseFlatIndex,
        overviewSelectedFlatIndex: _overviewSelectedFlatIndex,
        pageForFlatIndex: _pageForFlatIndex,
        mounted: mounted,
        setStateSafe: _setStateSafe,
        setOverviewSelectedFlatIndex: (value) =>
            _overviewSelectedFlatIndex = value,
        transformationController: _transformationController,
        overviewMatrixForPage: _overviewMatrixForPage,
        overviewPreviewScale: _overviewPreviewScale,
        setOverviewPinchCloseTriggered: (value) =>
            _overviewPinchCloseTriggered = value,
        setOverviewGestureLock: (value) => _overviewGestureLock = value,
        setOverviewPendingCloseFlatIndex: (value) =>
            _overviewPendingCloseFlatIndex = value,
        closeOverviewMode: _closeOverviewMode,
      );

  int _nearestFlatIndexFromCurrentTransform() => _overviewGeometry
      .nearestFlatIndexFromTransform(context, _transformationController.value);

  int _flatIndexForViewportPoint(Offset viewportPoint) =>
      _overviewGeometry.flatIndexForViewportPoint(
        context,
        viewportPoint,
        _transformationController.value,
      );

  Future<void> _handleOverviewCardTap(StagePageReference page) =>
      StageOverviewStateHelper.handleOverviewCardTap(
        page: page,
        allStagePages: _allStagePages,
        setStateSafe: _setStateSafe,
        setOverviewSelectedFlatIndex: (value) =>
            _overviewSelectedFlatIndex = value,
        closeOverviewMode: _closeOverviewMode,
      );

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

  void _onScreenDoubleTap() {
    if (_showOverviewLayer || _isOverviewClosing || _showOnboarding) return;
    unawaited(_openOverviewMode());
  }

  DisplayedStepProgress _displayStepProgressFor({
    required int rakaatIndex,
    required int stepIndex,
  }) => StageStepScreenFlowHelper.displayStepProgressFor(
    rakaats: _rakaats,
    prayerCode: widget.prayerCode,
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
    stepOrderIndexesForRakaatIndex: _stepOrderIndexesForRakaatIndex,
  );

  Widget _buildOverviewPage({
    required StagePageReference page,
    required String prayerTitle,
    required double cardTextSize,
  }) => buildStageOverviewPage(
    context: context,
    rakaats: _rakaats,
    page: page,
    prayerTitle: prayerTitle,
    cardTextSize: cardTextSize,
    stepOrderIndexesForRakaatIndex: _stepOrderIndexesForRakaatIndex,
    displayStepProgressFor: _displayStepProgressFor,
    entriesForPage: _entriesForPage,
    recitationEntriesForPage: _recitationEntriesForPage,
  );

  Widget _animateAppear(Widget child) =>
      StageStepScreenFlowHelper.animateAppear(
        contentAppeared: _contentAppeared,
        child: child,
      );

  Widget _animateRakaat(Widget child) =>
      StageStepScreenFlowHelper.animateRakaat(child);

  Widget _animateStepTransition(Widget child) =>
      StageStepScreenFlowHelper.animateStepTransition(
        token: _stepTransitionToken,
        direction: _stepTransitionDirection,
        child: child,
      );

  Future<void> _nextStep() => StageStepScreenFlowHelper.nextStep(
    context: context,
    isStageTransitioning: _isStageTransitioning,
    currentStepOrderIndexes: _currentStepOrderIndexes,
    clampedStepIndex: _clampedStepIndex,
    rakaats: _rakaats,
    rakaatIndex: _rakaatIndex,
    triggerLightHaptic: _triggerLightHaptic,
    animateStepTransitionTo: _animateStepTransitionTo,
    animateRakaatTransitionTo: _animateRakaatTransitionTo,
  );

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
  }) => StageStepScreenFlowHelper.animateStepTransitionTo(
    stepIndex: stepIndex,
    rakaatIndex: _rakaatIndex,
    currentStepOrderIndexes: _currentStepOrderIndexes,
    direction: direction,
    selectRakaatAndStep: _selectRakaatAndStep,
  );

  Future<void> _animateRakaatTransitionTo(
    int index, {
    required int stepIndex,
    required int direction,
  }) => StageStepScreenFlowHelper.animateRakaatTransitionTo(
    index: index,
    stepIndex: stepIndex,
    direction: direction,
    selectRakaatAndStep: _selectRakaatAndStep,
  );

  Future<void> _prevStep() => StageStepScreenFlowHelper.prevStep(
    isStageTransitioning: _isStageTransitioning,
    currentStepOrderIndexes: _currentStepOrderIndexes,
    clampedStepIndex: _clampedStepIndex,
    rakaats: _rakaats,
    rakaatIndex: _rakaatIndex,
    stepCountForRakaat: _stepCountForRakaat,
    triggerLightHaptic: _triggerLightHaptic,
    animateStepTransitionTo: _animateStepTransitionTo,
    animateRakaatTransitionTo: _animateRakaatTransitionTo,
  );

  void _handleHorizontalDragEnd(DragEndDetails details) =>
      StageStepScreenFlowHelper.handleHorizontalDragEnd(
        details: details,
        isOverviewMode: _isOverviewMode,
        horizontalSwipeVelocityThreshold: _horizontalSwipeVelocityThreshold,
        nextStep: _nextStep,
        prevStep: _prevStep,
      );

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
    final selectedGenderCode = GenderRepositoryMemory.instance
        .getSelectedGender()
        .id;
    final currentStepImageAsset = resolveStageStepImageAsset(
      explicitImageAsset: (currentStep?.imageAsset ?? ''),
      stepCode: currentStepCode,
      title: stepTitle,
      movementDescription: movementDescription,
      fallbackAsset: fallbackStepImageAsset,
      genderCode: selectedGenderCode,
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
    return buildStageStepScreenBody(
      context: context,
      backgroundColor: colors.background,
      allowExitPop: _allowExitPop,
      showOverviewLayer: _showOverviewLayer,
      isOverviewClosing: _isOverviewClosing,
      showTopBlur: _showTopBlur,
      isOverviewMode: _isOverviewMode,
      showPinned: _showPinned,
      showOverviewExitButton: _showOverviewExitButton,
      showTopControls: _showTopControls,
      showOnboarding: _showOnboarding,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onDoubleTap: _onScreenDoubleTap,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      mainScrollController: _scrollController,
      transformationController: _transformationController,
      onOverviewInteractionStart: _handleOverviewInteractionStart,
      onOverviewInteractionUpdate: _handleOverviewPanUpdate,
      onOverviewInteractionEnd: _handleOverviewInteractionEnd,
      overviewPanEnabled: !_overviewGestureLock,
      overviewDragFriction: _overviewDragFriction,
      overviewMinScale: _overviewPreviewScale,
      overviewCanvasSize: _overviewCanvasSize(),
      overviewPages: _allStagePages,
      overviewCardSize: _overviewCardSize(),
      pagePositionFor: (page) =>
          _getCardPosition(page.rakaatIndex, page.stepIndex),
      onPageTap: _handleOverviewCardTap,
      pageBuilder: (page) => _buildOverviewPage(
        page: page,
        prayerTitle: prayerTitle,
        cardTextSize: cardTextSize,
      ),
      topContentPadding: topContentPadding,
      onBack: () => unawaited(_popToHome()),
      onStage: _showStageSheet,
      stageButtonKey: _stageButtonKey,
      animateAppear: _animateAppear,
      onOpenOverview: _openOverviewMode,
      progressKey: _progressKey,
      prayerTitle: prayerTitle,
      totalRakaats: totalRakaats,
      rakaatIndex: rakaatIndex,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      stepProgress: stepProgress,
      animateStepTransition: _animateStepTransition,
      animateRakaat: _animateRakaat,
      stepTitle: stepTitle,
      movementDescription: movementDescription,
      cardTextSize: cardTextSize,
      softColor: colors.soft,
      textPrimaryColor: colors.textPrimary,
      textSecondaryColor: colors.textSecondary,
      currentStepImageAsset: currentStepImageAsset,
      fallbackStepImageAsset: fallbackStepImageAsset,
      hasAdditionalSurahSelector: hasAdditionalSurahSelector,
      additionalSurahOptions: additionalSurahOptions,
      selectedAdditionalSurahIndex: selectedAdditionalSurahIndex,
      onSelectAdditionalSurah: (optionIndex) => _onSelectAdditionalSurah(
        options: additionalSurahOptions,
        optionIndex: optionIndex,
      ),
      currentStepEntries: currentStepEntries,
      additionalSurahAnimationToken: _additionalSurahAnimationToken,
      entryKeyFor: _entryKey,
      keyForEntry: (index) {
        final entryKey = _entryKey(index);
        return _stepKeys.putIfAbsent(entryKey, () => GlobalKey());
      },
      playingStepKey: _playingStepKey,
      isAudioPlaying: _audio.isPlaying,
      audioProgress: audioProgress,
      onAyahTap: (i) {
        _triggerLightHaptic();
        if (i == _clampedAyahIndex) {
          unawaited(_togglePlay());
        } else {
          unawaited(_playStepAt(i));
        }
      },
      errorText: _error,
      navButtonsVisible: navButtonsVisible,
      hasPrevStageStep: hasPrevStageStep,
      hasNextStageStep: hasNextStageStep,
      canGoBack: canGoBack,
      canGoNext: canGoNext,
      onPrevStep: _prevStep,
      onNextStep: _nextStep,
      onboardingStepIndex: _onboardingStepIndex,
      onOnboardingNext: _onOnboardingNext,
      selectedAyahCardKey: selectedAyahCardKey,
      topControlInset: topControlInset,
      onOverviewExit: () => unawaited(_closeOverviewMode()),
    );
  }

  Future<void> _showStageSheet() async {
    if (_rakaats.isEmpty) return;
    _triggerLightHaptic();
    final selected = await showStageSectionSheet(
      context: context,
      rakaatCount: _rakaats.length,
      initialRakaatIndex: _rakaatIndex.clamp(0, _rakaats.length - 1),
      stepGroupsByRakaat: List.generate(
        _rakaats.length,
        _groupedStepsForRakaat,
        growable: false,
      ),
      onHaptic: _triggerLightHaptic,
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
  }) => StageStepScreenFlowHelper.jumpToRakaatAndStep(
    rakaats: _rakaats,
    currentRakaatIndex: _rakaatIndex,
    currentStepIndex: _clampedStepIndex,
    rakaatIndex: rakaatIndex,
    stepIndex: stepIndex,
    groupedStepsForRakaat: _groupedStepsForRakaat,
    animateStepTransitionTo: _animateStepTransitionTo,
    animateRakaatTransitionTo: _animateRakaatTransitionTo,
  );

  List<StageStepGroup> _groupedStepsForRakaat(int rakaatIndex) =>
      StageStepScreenFlowHelper.groupedStepsForRakaat(
        rakaats: _rakaats,
        rakaatIndex: rakaatIndex,
      );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
