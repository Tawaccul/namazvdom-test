import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import 'stage_overview_constants.dart';
import '../../core/audio/ayah_audio.dart';
import '../../core/audio/ayah_audio_controller.dart';
import '../settings/gender/data/gender_repository_memory.dart';
import '../settings/theme/presentation/theme_text_size_store.dart';
import 'animations/stage_neighbor_step_bundle.dart';
import 'state/stage_additional_surah_state.dart';
import 'state/stage_onboarding_state.dart';
import 'state/stage_scroll_visibility_state.dart';
import 'parts/stage_overview_page_builder.dart';
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
  static const double _horizontalSwipeVelocityThreshold =
      StageOverviewConstants.horizontalSwipeVelocityThreshold;
  static const double _overviewOpenScaleThreshold =
      StageOverviewConstants.overviewOpenScaleThreshold;
  static const double _overviewCloseScaleThreshold =
      StageOverviewConstants.overviewCloseScaleThreshold;
  static const double _overviewPageGap = StageOverviewConstants.overviewPageGap;
  static const double _overviewPreviewScale =
      StageOverviewConstants.overviewPreviewScale;
  static const double _overviewDragFriction =
      StageOverviewConstants.overviewDragFriction;
  static const double _overviewPanSpeedMultiplier =
      StageOverviewConstants.overviewPanSpeedMultiplier;
  static const double _overviewClosingTopInset =
      StageOverviewConstants.overviewClosingTopInset;
  static const double _overviewPreviewTopShift =
      StageOverviewConstants.overviewPreviewTopShift;
  static const double _overviewCanvasInset =
      StageOverviewConstants.overviewCanvasInset;
  static const double _overviewFitPadding =
      StageOverviewConstants.overviewFitPadding;
  static const Duration _overviewMatrixDuration =
      StageOverviewConstants.overviewMatrixDuration;
  static const _randomStageAudioAssets = <String>[
    'assets/audio/730cbdbfa3d664506abd7c2baf719491.mp3',
    'assets/audio/istiaza.mp3',
    'assets/audio/takbir.mp3',
  ];

  late final AyahAudio _audio;
  late final math.Random _randomAudio;
  late final TransformationController _transformationController;
  late final AnimationController _overviewAnimationController;
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _stageButtonKey = GlobalKey();
  final Map<String, GlobalKey> _stepKeys = {};
  final Map<String, String> _entryAudioUrls = {};
  late final StageScrollVisibilityState _scrollState;
  late final StageOnboardingState _onboarding;
  late final StageAdditionalSurahState _surahState;
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
  int _selectedAyahIndex = 0;
  bool _isOverviewMode = false;
  int _overviewSelectedFlatIndex = 0;
  int _overviewOriginFlatIndex = 0;
  bool _scaleGestureTriggered = false;
  bool _isOpeningOverviewMode = false;
  bool _isAnimatingOverviewMatrix = false;
  bool _isClampingOverviewTransform = false;
  bool _isStageTransitioning = false;
  bool _overviewPinchCloseTriggered = false;
  bool _overviewGestureLock = false;
  int? _overviewPendingCloseFlatIndex;
  int _stepTransitionToken = 0;
  int _stepTransitionDirection = 1;
  int _stepAudioSyncToken = 0;
  final bool _allowExitPop = false;

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
    _scrollState = StageScrollVisibilityState(
      notify: (fn) {
        if (mounted) setState(fn);
      },
      isMounted: () => mounted,
      getContext: () => context,
      scrollController: ScrollController(keepScrollOffset: false),
      progressKey: _progressKey,
      isOverviewLayerShowing: () => _showOverviewLayer,
    );
    _scrollState.scrollController.addListener(_scrollState.onScroll);
    _surahState = StageAdditionalSurahState(
      notify: (fn) {
        if (mounted) setState(fn);
      },
      isMounted: () => mounted,
      getContext: () => context,
      getRakaats: () => _rakaats,
      getRakaatIndex: () => _rakaatIndex,
      translateKey: _translateKey,
      onRakaatsUpdated: (updated) => setState(() => _rakaats = updated),
      onNavigateToStep: (stepIndex) => _selectStep(
        stepIndex,
        playIfAutoplay: false,
        animateStepTransition: false,
        jumpToTop: false,
      ),
      cancelAutoplay: ({bool disableAutoplay = false}) =>
          _cancelAutoplaySequence(disableAutoplay: disableAutoplay),
      setError: (msg) {
        if (mounted) setState(() => _error = msg);
      },
    );
    _onboarding = StageOnboardingState(
      notify: (fn) {
        if (mounted) setState(fn);
      },
      isMounted: () => mounted,
      getStepKey: (key) => _stepKeys[key],
      getOnboardingEntryKey: () => _entryKey(_clampedAyahIndex),
      animateToTop: _animateToTop,
      alwaysShow: _alwaysShowStageOnboarding,
    );
    _onboarding.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollState.updatePinned();
      _scrollState.markContentAppeared();
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

  String _translateKey(String? key, {String fallback = ''}) {
    final normalized = (key ?? '').trim();
    if (normalized.isEmpty) return fallback;
    final translated = context.t(normalized);
    if (translated == normalized) {
      return fallback.isEmpty ? normalized : fallback;
    }
    return translated;
  }

  void _jumpToTop() => _scrollState.jumpToTop();

  Future<void> _animateToTop() => _scrollState.animateToTop();

  void _triggerLightHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioTick);
    _audio.dispose();
    _scrollState.scrollController.removeListener(_scrollState.onScroll);
    _scrollState.scrollController.dispose();
    _transformationController.removeListener(_handleOverviewTransformChanged);
    _overviewAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
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
    setSelectedAyahIndex: (next) {
      setState(() => _selectedAyahIndex = next);
      _scrollSelectedAyahIntoView();
    },
    getSelectedAyahStep: () => _selectedAyahStep,
    getStepKey: () => _stepKey,
    isAutoplayEnabled: () => _autoplayEnabled,
    setAyah: _audio.setAyah,
    stepToAyah: _stepToAyah,
    setPlayingStepKey: (value) => _playingStepKey = value,
    setStartedPlaybackStepKey: (value) => _startedPlaybackStepKey = value,
    playCurrent: _playCurrent,
  );

  void _scrollSelectedAyahIntoView({int attempt = 0}) {
    if (_showOverviewLayer || _isOverviewClosing) return;
    final key = _stepKeys[_entryKey(_clampedAyahIndex)];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx == null) {
        if (attempt < 4) _scrollSelectedAyahIntoView(attempt: attempt + 1);
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

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
    _stepAudioSyncToken++;
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
        if (jumpToTop) {
          _scrollState.showPinned = false;
        }
        if (animateStepTransition) {
          _stepTransitionToken++;
          _stepTransitionDirection = direction >= 0 ? 1 : -1;
        }
      });
      if (jumpToTop) {
        _jumpToTop();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollState.updatePinned();
        });
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

  Future<void> _selectRakaatAndStepForCarousel(
    int rakaatIndex,
    int stepIndex, {
    bool playIfAutoplay = false,
    int direction = 1,
    bool jumpToTop = true,
  }) async {
    if (_rakaats.isEmpty || _isStageTransitioning) return;
    _isStageTransitioning = true;

    final nextRakaat = rakaatIndex.clamp(0, _rakaats.length - 1);
    final stepCount = _stepCountForRakaat(nextRakaat);
    final nextStep = stepCount == 0 ? 0 : stepIndex.clamp(0, stepCount - 1);
    final resumeAutoplay = playIfAutoplay && _autoplayEnabled;
    final syncToken = ++_stepAudioSyncToken;

    _cancelAutoplaySequence(disableAutoplay: true);
    if (!mounted) {
      _isStageTransitioning = false;
      return;
    }

    setState(() {
      _rakaatIndex = nextRakaat;
      _stepIndex = nextStep;
      _selectedAyahIndex = 0;
      _playingStepKey = null;
      _startedPlaybackStepKey = null;
      if (jumpToTop) {
        _scrollState.showPinned = false;
      }
      _stepTransitionDirection = direction >= 0 ? 1 : -1;
    });
    if (jumpToTop) {
      _jumpToTop();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollState.updatePinned();
      });
    }
    _isStageTransitioning = false;
    unawaited(
      _syncSelectedStepAudioAfterCarousel(
        syncToken,
        resumeAutoplay: resumeAutoplay,
      ),
    );
  }

  Future<void> _syncSelectedStepAudioAfterCarousel(
    int syncToken, {
    required bool resumeAutoplay,
  }) async {
    try {
      await _audio.pause();
      if (!mounted || syncToken != _stepAudioSyncToken) return;

      final step = _selectedAyahStep;
      if (step == null) return;
      if (step.hasAudio) {
        await _audio.setAyah(_stepToAyah(step, _stepKey));
      }
      if (!mounted || syncToken != _stepAudioSyncToken) return;
      if (resumeAutoplay && step.hasAudio) {
        await _playCurrent();
      }
    } catch (error) {
      if (!mounted || syncToken != _stepAudioSyncToken) return;
      setState(() => _error = error.toString());
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

  /// Собирает данные соседнего шага для ghost-карточки в карусели.
  /// [direction]: -1 = предыдущий, +1 = следующий.
  StageNeighborStepBundle? _resolveNeighborStepBundle({
    required int direction,
    required int currentStepCount,
    required String genderCode,
  }) {
    if (_rakaats.isEmpty) return null;
    var targetRakaat = _rakaatIndex;
    var targetStep = _clampedStepIndex + direction;

    if (targetStep < 0) {
      targetRakaat -= 1;
      if (targetRakaat < 0) return null;
      final prevCount = _stepCountForRakaat(targetRakaat);
      targetStep = prevCount - 1;
    } else if (targetStep >= currentStepCount) {
      targetRakaat += 1;
      if (targetRakaat >= _rakaats.length) return null;
      targetStep = 0;
    }

    final entries = _entriesForPage(
      rakaatIndex: targetRakaat,
      stepIndex: targetStep,
    );
    final recitationEntries = _recitationEntriesForPage(
      rakaatIndex: targetRakaat,
      stepIndex: targetStep,
    );
    final firstEntry = entries.isNotEmpty ? entries.first : null;
    final stepTitle = (firstEntry?.title ?? '').trim().isEmpty
        ? context.t('stage.defaultStepTitle')
        : firstEntry!.title;
    final movementDescription = (firstEntry?.movementDescription ?? '').trim();
    final fallbackImage = _rakaats[targetRakaat].imageAsset;
    final stepImageAsset = resolveStageStepImageAsset(
      explicitImageAsset: firstEntry?.imageAsset ?? '',
      stepCode: firstEntry?.stepCode ?? '',
      title: stepTitle,
      movementDescription: movementDescription,
      fallbackAsset: fallbackImage,
      genderCode: genderCode,
    );

    return StageNeighborStepBundle(
      stepTitle: stepTitle,
      movementDescription: movementDescription,
      stepImageAsset: stepImageAsset,
      fallbackStepImageAsset: fallbackImage,
      entries: recitationEntries,
    );
  }

  StageOverviewGeometry get _overviewGeometry => StageOverviewGeometry(
    pageCount: _allStagePages.length,
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

  Offset _getCardPosition(int rakaatIndex, int stepIndex) => _overviewGeometry
      .cardPosition(context, _allStagePages, rakaatIndex, stepIndex);

  Size _overviewCanvasSize() => _overviewGeometry.canvasSize(context);

  Matrix4 _overviewMatrixForPage(StagePageReference page, {double scale = 1}) =>
      _overviewGeometry.matrixForPage(
        context,
        _allStagePages,
        page,
        scale: scale,
      );

  void _setStateSafe(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _handleOverviewTransformChanged() =>
      StageOverviewStateHelper.handleOverviewTransformChanged(
        showOverviewLayer: _showOverviewLayer,
        isAnimatingOverviewMatrix: _isAnimatingOverviewMatrix,
        isClampingOverviewTransform: _isClampingOverviewTransform,
        clampOverviewTransformYOnly: _clampOverviewTransformYOnly,
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

  Matrix4 _clampOverviewTransformYOnly(Matrix4 matrix) =>
      _overviewGeometry.clampTransformYOnly(context, matrix);

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

  Future<void> _openOverviewMode() async {
    if (_isOpeningOverviewMode ||
        _isOverviewMode ||
        _showOverviewLayer ||
        _isOverviewClosing ||
        _isAnimatingOverviewMatrix ||
        _isStageTransitioning) {
      return;
    }
    _isOpeningOverviewMode = true;
    try {
      await StageOverviewStateHelper.openOverviewMode(
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
        setTopControlsRevealToken: (value) =>
            _scrollState.topControlsRevealToken = value,
        topControlsRevealToken: _scrollState.topControlsRevealToken,
        setStateSafe: _setStateSafe,
        setOverviewOriginFlatIndex: (value) => _overviewOriginFlatIndex = value,
        setOverviewSelectedFlatIndex: (value) =>
            _overviewSelectedFlatIndex = value,
        setOverviewPinchCloseTriggered: (value) =>
            _overviewPinchCloseTriggered = value,
        setOverviewGestureLock: (value) => _overviewGestureLock = value,
        setOverviewPendingCloseFlatIndex: (value) =>
            _overviewPendingCloseFlatIndex = value,
        setShowTopControls: (value) => _scrollState.showTopControls = value,
        setShowOverviewLayer: (value) => _showOverviewLayer = value,
        setIsOverviewMode: (value) => _isOverviewMode = value,
        setIsOverviewClosing: (value) => _isOverviewClosing = value,
        setShowOverviewExitButton: (value) => _showOverviewExitButton = value,
        setShowPinned: (value) => _scrollState.showPinned = value,
        clearAudioPlaybackKeys: () {
          _playingStepKey = null;
          _startedPlaybackStepKey = null;
        },
        isOverviewLayerShown: () => _showOverviewLayer,
      );
    } finally {
      _isOpeningOverviewMode = false;
    }
  }

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
        setShowPinned: (value) => _scrollState.showPinned = value,
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
        nextToken: _scrollState.topControlsRevealToken + 1,
        setTopControlsRevealToken: (value) =>
            _scrollState.topControlsRevealToken = value,
        mounted: () => mounted,
        topControlsRevealToken: () => _scrollState.topControlsRevealToken,
        showOverviewLayer: () => _showOverviewLayer,
        showTopControls: () => _scrollState.showTopControls,
        setStateSafe: _setStateSafe,
        setShowTopControls: (value) => _scrollState.showTopControls = value,
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
    if (_showOverviewLayer ||
        _isOverviewClosing ||
        _onboarding.showOnboarding) {
      return;
    }
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
    required double topInset,
  }) => buildStageOverviewPage(
    context: context,
    rakaats: _rakaats,
    page: page,
    prayerTitle: prayerTitle,
    cardTextSize: cardTextSize,
    topInset: topInset,
    stepOrderIndexesForRakaatIndex: _stepOrderIndexesForRakaatIndex,
    displayStepProgressFor: _displayStepProgressFor,
    entriesForPage: _entriesForPage,
    recitationEntriesForPage: _recitationEntriesForPage,
    selectedAdditionalSurahCode: _surahState.selectedAdditionalSurahCode,
  );

  Widget _animateAppear(Widget child) =>
      StageStepScreenFlowHelper.animateAppear(
        contentAppeared: _scrollState.contentAppeared,
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
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
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

  Future<void> _nextStepWithoutTransition() async {
    if (_currentStepOrderIndexes.isEmpty || _isStageTransitioning) return;
    if (_clampedStepIndex < _currentStepOrderIndexes.length - 1) {
      await _selectRakaatAndStepForCarousel(
        _rakaatIndex,
        _clampedStepIndex + 1,
        playIfAutoplay: false,
        direction: 1,
      );
      return;
    }
    if (_rakaats.isEmpty) return;
    final next = (_rakaatIndex + 1).clamp(0, _rakaats.length - 1);
    if (next == _rakaatIndex) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('stage.prayerCompleted'))),
      );
      return;
    }
    await _selectRakaatAndStepForCarousel(
      next,
      0,
      playIfAutoplay: false,
      direction: 1,
    );
  }

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

  Future<void> _prevStepWithoutTransition() async {
    if (_currentStepOrderIndexes.isEmpty || _isStageTransitioning) return;
    if (_clampedStepIndex > 0) {
      await _selectRakaatAndStepForCarousel(
        _rakaatIndex,
        _clampedStepIndex - 1,
        playIfAutoplay: false,
        direction: -1,
      );
      return;
    }
    if (_rakaats.isEmpty) return;
    final prev = (_rakaatIndex - 1).clamp(0, _rakaats.length - 1);
    if (prev == _rakaatIndex) return;
    final prevStepCount = _stepCountForRakaat(prev);
    final prevStepIndex = prevStepCount == 0 ? 0 : prevStepCount - 1;
    await _selectRakaatAndStepForCarousel(
      prev,
      prevStepIndex,
      playIfAutoplay: false,
      direction: -1,
    );
  }

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
        _surahState.isAdditionalSurahStep(currentStep);
    final selectedAdditionalSurahIndex = _surahState.selectedIndexForStep(
      additionalSurahOptions,
      currentStep,
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

    // Соседние шаги для карусельного ghost-контента.
    final prevGhost = hasPrevStageStep
        ? _resolveNeighborStepBundle(
            direction: -1,
            currentStepCount: _stepCountForRakaat(_rakaatIndex),
            genderCode: selectedGenderCode,
          )
        : null;
    final nextGhost = hasNextStageStep
        ? _resolveNeighborStepBundle(
            direction: 1,
            currentStepCount: _stepCountForRakaat(_rakaatIndex),
            genderCode: selectedGenderCode,
          )
        : null;

    return buildStageStepScreenBody(
      context: context,
      backgroundColor: colors.background,
      allowExitPop: _allowExitPop,
      showOverviewLayer: _showOverviewLayer,
      isOverviewClosing: _isOverviewClosing,
      showTopBlur: _scrollState.showTopBlur,
      isOverviewMode: _isOverviewMode,
      showPinned: _scrollState.showPinned,
      showOverviewExitButton: _showOverviewExitButton,
      showTopControls: _scrollState.showTopControls,
      showOnboarding: _onboarding.showOnboarding,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onDoubleTap: _onScreenDoubleTap,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      mainScrollController: _scrollState.scrollController,
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
        topInset: topContentPadding,
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
      onSelectAdditionalSurah: (optionIndex) =>
          _surahState.onSelectAdditionalSurah(
            options: additionalSurahOptions,
            optionIndex: optionIndex,
          ),
      currentStepEntries: currentStepEntries,
      additionalSurahAnimationToken: _surahState.additionalSurahAnimationToken,
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
      onPrevStepProgrammatic: _prevStepWithoutTransition,
      onNextStepProgrammatic: _nextStepWithoutTransition,
      onboardingStepIndex: _onboarding.stepIndex,
      onOnboardingNext: _onboarding.onNext,
      selectedAyahCardKey: selectedAyahCardKey,
      topControlInset: topControlInset,
      onOverviewExit: () => unawaited(_closeOverviewMode()),
      prevGhost: prevGhost,
      nextGhost: nextGhost,
      onCarouselDragStarted: _scrollState.jumpScrollToTop,
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
