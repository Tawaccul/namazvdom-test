import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../stage/stage_overview_constants.dart';
import '../../stage/stage_overview_geometry.dart';
import '../../../core/audio/ayah_audio.dart';
import '../../../core/audio/ayah_audio_controller.dart';
import '../../../core/text/transliteration_localizer.dart';
import '../data/ablution_content_cache.dart';
import '../../onboarding/data/onboarding_repository_memory.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../../settings/language/data/language_repository_memory.dart';
import '../../settings/theme/presentation/theme_text_size_store.dart';
import '../../quran/model/quran_ayah.dart';
import 'ablution_screen.dart';
import 'models/ablution_manifest_models.dart';
import 'parts/ablution_overview.dart';
import 'parts/ablution_page_content.dart';
import 'parts/ablution_screen_body.dart';
import 'parts/ablution_step_selector_sheet.dart';


class AblutionScreenState extends State<AblutionScreen>
    with SingleTickerProviderStateMixin {
  static const double _topBlurShowOffset = 38;
  static const double _horizontalSwipeVelocityThreshold = StageOverviewConstants.horizontalSwipeVelocityThreshold;
  static const double _overviewOpenScaleThreshold = StageOverviewConstants.overviewOpenScaleThreshold;
  static const double _overviewCloseScaleThreshold = StageOverviewConstants.overviewCloseScaleThreshold;
  static const double _overviewPageGap = StageOverviewConstants.overviewPageGap;
  static const double _overviewPreviewScale = StageOverviewConstants.overviewPreviewScale;
  static const double _overviewDragFriction = StageOverviewConstants.overviewDragFriction;
  static const double _overviewPanSpeedMultiplier = StageOverviewConstants.overviewPanSpeedMultiplier;
  static const double _overviewClosingTopInset = StageOverviewConstants.overviewClosingTopInset;
  static const double _overviewPreviewTopShift = StageOverviewConstants.overviewPreviewTopShift;
  static const double _overviewCanvasInset = StageOverviewConstants.overviewCanvasInset;
  static const double _overviewFitPadding = StageOverviewConstants.overviewFitPadding;
  static const Duration _overviewMatrixDuration = StageOverviewConstants.overviewMatrixDuration;
  late final AyahAudio _audio;
  late final TransformationController _overviewTransformationController;
  late final AnimationController _overviewAnimationController;
  final GlobalKey _stageButtonKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _onboardingHighlightKey = GlobalKey();
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  final Map<int, ScrollController> _overviewScrollControllers = {};
  final Map<int, bool> _overviewOverflowByPage = {};
  late final Future<AblutionManifest> _manifestFuture;
  final Map<String, bool> _assetExistsMemo = {};
  AblutionManifest? _manifest;
  int _stepIndex = 0;
  String? _playingStepAudioKey;
  int _stepTransitionToken = 0;
  int _stepTransitionDirection = 1;
  bool _showOverviewLayer = false;
  bool _isOverviewClosing = false;
  bool _showOverviewExitButton = false;
  bool _isOverviewMode = false;
  int _overviewSelectedFlatIndex = 0;
  int _overviewOriginFlatIndex = 0;
  bool _scaleGestureTriggered = false;
  bool _isAnimatingOverviewMatrix = false;
  bool _isClampingOverviewTransform = false;
  bool _overviewPinchCloseTriggered = false;
  bool _overviewGestureLock = false;
  int? _overviewPendingCloseFlatIndex;
  bool _showTopControls = true;
  int _topControlsRevealToken = 0;
  bool _allowExitPop = false;
  bool _showTopBlur = false;
  bool _showOnboarding = false;
  int _onboardingStepIndex = 0;
  bool _onboardingStepAdvancing = false;
  @override
  void initState() {
    super.initState();
    _overviewTransformationController = TransformationController();
    _overviewTransformationController.addListener(
      _handleOverviewTransformChanged,
    );
    _overviewAnimationController = AnimationController(
      vsync: this,
      duration: _overviewMatrixDuration,
    );
    _audio = AyahAudioController()..addListener(_onAudioTick);
    _scrollController.addListener(_onScroll);
    _showOnboarding = OnboardingRepositoryMemory.instance
        .consumeStageOnboarding();
    _onboardingStepIndex = 0;
    _manifestFuture = _loadManifest();
  }
  @override
  void dispose() {
    _audio.removeListener(_onAudioTick);
    unawaited(_audio.dispose());
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (final controller in _overviewScrollControllers.values) {
      controller.dispose();
    }
    _overviewTransformationController.removeListener(
      _handleOverviewTransformChanged,
    );
    _overviewAnimationController.dispose();
    _overviewTransformationController.dispose();
    super.dispose();
  }
  void _onAudioTick() {
    if (!mounted) return;
    setState(() {});
  }
  void _onScroll() {
    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _topBlurShowOffset;
    if (shouldShow == _showTopBlur) return;
    setState(() => _showTopBlur = shouldShow);
  }
  Future<void> _animateToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }
  void _scrollOnboardingStepIntoView({int attempt = 0}) {
    final ctx = _onboardingHighlightKey.currentContext;
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
  void _handleOnboardingStepChanged(int stepIndex) {
    if (stepIndex != 2) return;
    _scrollOnboardingStepIntoView();
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
  Future<AblutionManifest> _loadManifest() async {
    final json = await AblutionContentCache.loadManifestJson();
    return AblutionManifest.fromJson(json);
  }
  int get _totalSteps => _manifest?.steps.length ?? 0;
  int get _clampedStepIndex {
    final total = _totalSteps;
    if (total == 0) return 0;
    return _stepIndex.clamp(0, total - 1);
  }
  AblutionStepManifest? get _currentStep {
    if (_manifest == null || _manifest!.steps.isEmpty) return null;
    return _manifest!.steps[_clampedStepIndex];
  }
  String _audioStepKey(AblutionStepManifest step) => 'ablution-step-${step.id}';
  bool _isStepAudioPlaying(AblutionStepManifest step) =>
      _playingStepAudioKey == _audioStepKey(step) && _audio.isPlaying;
  Future<bool> _assetExists(String assetPath) async {
    final memoized = _assetExistsMemo[assetPath];
    if (memoized != null) return memoized;
    try {
      await rootBundle.load(assetPath);
      _assetExistsMemo[assetPath] = true;
      return true;
    } catch (_) {
      _assetExistsMemo[assetPath] = false;
      return false;
    }
  }
  Future<String> _resolveStepAudioAsset(AblutionStepManifest step) async {
    final explicit = step.audio.trim();
    if (explicit.isNotEmpty && await _assetExists(explicit)) {
      return explicit;
    }
    if (step.id > 0) {
      final byId = 'assets/audio/ablution/${step.id}.mp3';
      if (await _assetExists(byId)) return byId;
      final byLegacyId = 'assets/audio/ablution/ablution_${step.id}.mp3';
      if (await _assetExists(byLegacyId)) return byLegacyId;
    }
    return '';
  }
  String _stepImageAsset(AblutionStepManifest step) {
    final genderCode = GenderRepositoryMemory.instance
        .getSelectedGender()
        .id
        .trim()
        .toLowerCase();
    final normalizedGender = genderCode == 'female' ? 'female' : 'male';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemePrefix = isDark ? 'b' : 'w';
    return 'assets/ablution/images/$normalizedGender/'
        '${currentThemePrefix}_ablution_${normalizedGender}_${step.id}.svg';
  }
  QuranAyah _stepToAyah(
    AblutionStepManifest step,
    String key,
    String audioUrl,
  ) {
    final text = step.text!;
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    return QuranAyah(
      surahId: 0,
      ayahId: key.hashCode,
      surahNameAr: '',
      surahNameEn: '',
      ayahCount: 1,
      ayahAr: text.arabic,
      ayahEn: text.translationKey,
      ayahTr: localizedTransliteration(text.transliteration, languageCode),
      reciterId: 'ablution',
      reciterName: 'ablution',
      audioUrl: audioUrl,
    );
  }
  void _stopAudioSilently() {
    _playingStepAudioKey = null;
    unawaited(_audio.stop());
  }
  Future<void> _toggleStepAyahAudio(AblutionStepManifest step) async {
    if (step.text == null) return;
    final audioUrl = await _resolveStepAudioAsset(step);
    if (audioUrl.isEmpty) return;
    final key = _audioStepKey(step);
    final isCurrentAudio = _playingStepAudioKey == key;
    try {
      if (!isCurrentAudio) {
        _playingStepAudioKey = key;
        await _audio.setAyah(_stepToAyah(step, key, audioUrl));
      }
      if (_audio.isPlaying && isCurrentAudio) {
        await _audio.pause();
      } else {
        await _audio.play();
      }
    } catch (_) {
      _playingStepAudioKey = null;
      await _audio.stop();
    }
    if (!mounted) return;
    setState(() {});
  }
  Future<void> _prevStep() async {
    if (_totalSteps == 0) return;
    if (_clampedStepIndex > 0) {
      await _selectStepIndex(_clampedStepIndex - 1, direction: -1);
      return;
    }
    _stopAudioSilently();
    await _popToHome();
  }
  Future<void> _nextStep() async {
    if (_totalSteps == 0) return;
    if (_clampedStepIndex < _totalSteps - 1) {
      await _selectStepIndex(_clampedStepIndex + 1, direction: 1);
      return;
    }
    _stopAudioSilently();
  }
  Future<void> _popToHome() async {
    if (!mounted) return;
    setState(() => _allowExitPop = true);
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      setState(() => _allowExitPop = false);
    }
  }
  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_horizontalSwipeVelocityThreshold) {
      unawaited(_nextStep());
      return;
    }
    if (velocity >= _horizontalSwipeVelocityThreshold) {
      unawaited(_prevStep());
    }
  }
  String _localizedStepTransliteration(AblutionStepManifest step) {
    final text = step.text;
    if (text == null) return '';
    return localizedTransliteration(
      text.transliteration,
      LanguageRepositoryMemory.instance.getSelectedLanguage().id,
    );
  }
  Future<void> _selectStepIndex(
    int stepIndex, {
    required int direction,
    bool animateTransition = true,
  }) async {
    if (_totalSteps == 0) return;
    final nextStep = stepIndex.clamp(0, _totalSteps - 1);
    if (nextStep == _clampedStepIndex) return;
    _stopAudioSilently();
    if (!mounted) return;
    setState(() {
      _stepIndex = nextStep;
      if (animateTransition) {
        _stepTransitionToken++;
        _stepTransitionDirection = direction >= 0 ? 1 : -1;
      }
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }
  Future<void> _showStepSelector() async {
    final manifest = _manifest;
    if (manifest == null || manifest.steps.isEmpty) return;
    final selected = await showAblutionStepSelectorSheet(
      context: context,
      manifest: manifest,
    );
    if (!mounted || selected == null) return;
    final next = selected.clamp(0, _totalSteps - 1);
    if (next == _clampedStepIndex) return;
    await _selectStepIndex(next, direction: next >= _clampedStepIndex ? 1 : -1);
  }
  Widget _animateStepTransition(Widget child) {
    final direction = _stepTransitionDirection >= 0 ? 1.0 : -1.0;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(_stepTransitionToken),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Transform.translate(
          offset: Offset(direction * 34.w * (1 - value), 0),
          child: animatedChild,
        );
      },
      child: child,
    );
  }
  List<AblutionOverviewPageReference> get _allOverviewPages {
    final total = _totalSteps;
    if (total <= 0) return const [];
    return List<AblutionOverviewPageReference>.generate(
      total,
      (index) => AblutionOverviewPageReference(stepIndex: index),
      growable: false,
    );
  }
  int get _currentFlatPageIndex {
    final pages = _allOverviewPages;
    if (pages.isEmpty) return 0;
    return _clampedStepIndex.clamp(0, pages.length - 1);
  }
  AblutionOverviewPageReference? _pageForFlatIndex(int flatIndex) {
    final pages = _allOverviewPages;
    if (pages.isEmpty) return null;
    return pages[flatIndex.clamp(0, pages.length - 1)];
  }
  StageOverviewGeometry get _overviewGeometry => StageOverviewGeometry(
    pageCount: _allOverviewPages.length,
    previewScale: _overviewPreviewScale,
    pageGap: _overviewPageGap,
    canvasInset: _overviewCanvasInset,
    fitPadding: _overviewFitPadding,
    closingTopInset: _overviewClosingTopInset,
    previewTopShift: _overviewPreviewTopShift,
  );

  double _overviewRestingTopInset() => _overviewGeometry.restingTopInset(context);
  Size _overviewCardSize() => _overviewGeometry.cardSize(context);
  Size _overviewCanvasSize() => _overviewGeometry.canvasSize(context);
  Offset _getCardPosition(int flatIndex) =>
      _overviewGeometry.cardPositionForFlatIndex(context, flatIndex);
  Matrix4 _overviewMatrixForPage(
    AblutionOverviewPageReference page, {
    double scale = 1,
  }) => _overviewGeometry.matrixForFlatIndex(context, page.stepIndex, scale: scale);

  ScrollController _overviewScrollControllerFor(int pageId) {
    return _overviewScrollControllers.putIfAbsent(
      pageId,
      () => ScrollController(keepScrollOffset: false),
    );
  }
  void _setOverviewOverflow(int pageId, bool hasOverflow) {
    final previous = _overviewOverflowByPage[pageId] ?? false;
    if (previous == hasOverflow || !mounted) return;
    setState(() => _overviewOverflowByPage[pageId] = hasOverflow);
  }
  void _handleOverviewTransformChanged() {
    if (!_showOverviewLayer ||
        _isAnimatingOverviewMatrix ||
        _isClampingOverviewTransform) {
      return;
    }
    final clamped = _overviewGeometry.clampTransform(
      context,
      _overviewTransformationController.value,
    );
    final current = _overviewTransformationController.value;
    if (_overviewGeometry.matricesAreEqual(current, clamped)) return;
    _isClampingOverviewTransform = true;
    _overviewTransformationController.value = clamped;
    _isClampingOverviewTransform = false;
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
          begin: Matrix4.copy(_overviewTransformationController.value),
          end: target,
        ).animate(
          CurvedAnimation(parent: _overviewAnimationController, curve: curve),
        );
    void listener() {
      _overviewTransformationController.value = animation.value;
    }
    _isAnimatingOverviewMatrix = true;
    animation.addListener(listener);
    try {
      await _overviewAnimationController.forward();
    } finally {
      animation.removeListener(listener);
      _overviewTransformationController.value = target;
      _isAnimatingOverviewMatrix = false;
    }
  }
  int _nearestFlatIndexFromCurrentTransform() =>
      _overviewGeometry.nearestFlatIndexFromTransform(
        context,
        _overviewTransformationController.value,
      );

  int _flatIndexForViewportPoint(Offset viewportPoint) =>
      _overviewGeometry.flatIndexForViewportPoint(
        context,
        viewportPoint,
        _overviewTransformationController.value,
      );
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
      final currentScale = _overviewTransformationController.value.storage[0]
          .clamp(_overviewPreviewScale, 1.0)
          .toDouble();
      if (details.scale >= _overviewCloseScaleThreshold ||
          currentScale >= _overviewCloseScaleThreshold) {
        _overviewPinchCloseTriggered = true;
        final closestFlatIndex =
            _overviewPendingCloseFlatIndex ??
            _nearestFlatIndexFromCurrentTransform();
        final page = _pageForFlatIndex(closestFlatIndex);
        if (page == null) return;
        _overviewTransformationController.value = _overviewMatrixForPage(
          page,
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
    final boosted = Matrix4.copy(_overviewTransformationController.value)
      ..translateByDouble(extraDx, 0, 0, 1);
    _isClampingOverviewTransform = true;
    _overviewTransformationController.value = _overviewGeometry.clampTransform(context, boosted);
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
  Future<void> _openOverviewMode() async {
    if (_isOverviewMode || _showOverviewLayer || _isAnimatingOverviewMatrix) {
      return;
    }
    final currentPage = _pageForFlatIndex(_currentFlatPageIndex);
    if (currentPage == null) return;
    _stopAudioSilently();
    final currentFlatIndex = _currentFlatPageIndex;
    _topControlsRevealToken++;
    _overviewTransformationController.value = _overviewMatrixForPage(
      currentPage,
    );
    if (!mounted) return;
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
  Future<void> _closeOverviewFromPinch() async {
    if (!_showOverviewLayer || _isAnimatingOverviewMatrix) return;
    final targetFlatIndex =
        _overviewPendingCloseFlatIndex ?? _overviewSelectedFlatIndex;
    final selected = _pageForFlatIndex(targetFlatIndex);
    if (selected == null) return;
    if (_overviewSelectedFlatIndex != targetFlatIndex && mounted) {
      setState(() => _overviewSelectedFlatIndex = targetFlatIndex);
    }
    _overviewTransformationController.value = _overviewMatrixForPage(
      selected,
      scale: _overviewPreviewScale,
    );
    _overviewPinchCloseTriggered = true;
    _overviewGestureLock = true;
    _overviewPendingCloseFlatIndex = null;
    await _closeOverviewMode(applySelection: true);
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
      if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _isOverviewClosing = true;
      _showOverviewExitButton = false;
    });
    await _animateOverviewMatrix(
      _overviewMatrixForPage(selected),
      duration: _overviewMatrixDuration,
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    if (applySelection) {
      final direction = selected.stepIndex >= _clampedStepIndex ? 1 : -1;
      await _selectStepIndex(
        selected.stepIndex,
        direction: direction,
        animateTransition: false,
      );
    }
    if (!mounted) return;
    setState(() {
      _showOverviewLayer = false;
      _isOverviewMode = false;
      _isOverviewClosing = false;
      _showOverviewExitButton = false;
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
  Future<void> _handleOverviewCardTap(
    AblutionOverviewPageReference page,
  ) async {
    setState(() => _overviewSelectedFlatIndex = page.stepIndex);
    await _closeOverviewMode(applySelection: true);
  }
  void _onScaleStart(ScaleStartDetails details) {
    _scaleGestureTriggered = false;
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_showOverviewLayer ||
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
    if (_showOverviewLayer || _isOverviewClosing) return;
    unawaited(_openOverviewMode());
  }
  Widget _buildOverviewPage(
    AblutionOverviewPageReference page,
    AblutionManifest manifest,
    String title,
    double pageHeight,
  ) {
    final pageId = page.stepIndex;
    return buildAblutionOverviewPage(
      context: context,
      page: page,
      manifest: manifest,
      title: title,
      pageHeight: pageHeight,
      topInset: _overviewRestingTopInset(),
      cardTextSize: ThemeTextSizeStore.textSize,
      pageScrollController: _overviewScrollControllerFor(pageId),
      shouldScheduleOverflowCheck: !_overviewOverflowByPage.containsKey(pageId),
      mounted: mounted,
      setOverviewOverflow: _setOverviewOverflow,
      stepImageAsset: _stepImageAsset,
      localizedStepTransliteration: _localizedStepTransliteration,
    );
  }
  Widget _buildPageContent({
    required AblutionStepManifest step,
    required int stepNumber,
    required int totalSteps,
    required double progress,
    required String title,
    ScrollController? scrollController,
    required VoidCallback onBack,
    required VoidCallback onStage,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) => buildAblutionPageContent(
    context: context,
    step: step,
    stepNumber: stepNumber,
    totalSteps: totalSteps,
    progress: progress,
    title: title,
    showTopControls: _showTopControls,
    stageButtonKey: _stageButtonKey,
    progressKey: _progressKey,
    onboardingHighlightKey: _onboardingHighlightKey,
    animateStepTransition: _animateStepTransition,
    stepImageAsset: _stepImageAsset,
    isStepAudioPlaying: _isStepAudioPlaying,
    localizedStepTransliteration: _localizedStepTransliteration,
    onBack: onBack,
    onStage: onStage,
    onPrev: onPrev,
    onNext: onNext,
    onOpenOverview: _openOverviewMode,
    onToggleStepAudio: (step) => unawaited(_toggleStepAyahAudio(step)),
    scrollController: scrollController,
  );
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final cardTextSize = ThemeTextSizeStore.textSize;
    final topControlInset = _overviewRestingTopInset();
    return buildAblutionScreenBody(
      context: context,
      manifestFuture: _manifestFuture,
      currentManifest: _manifest,
      onManifestLoaded: (manifest) => _manifest ??= manifest,
      allowExitPop: _allowExitPop,
      showOverviewLayer: _showOverviewLayer,
      isOverviewClosing: _isOverviewClosing,
      showTopBlur: _showTopBlur,
      showOverviewExitButton: _showOverviewExitButton,
      showOnboarding: _showOnboarding,
      showTopControls: _showTopControls,
      onboardingStepIndex: _onboardingStepIndex,
      topControlInset: topControlInset,
      bottomInset: bottomInset,
      cardTextSize: cardTextSize,
      backgroundColor: colors.background,
      textPrimaryColor: colors.textPrimary,
      textSecondaryColor: colors.textSecondary,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onDoubleTap: _onScreenDoubleTap,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      buildPageContent:
          ({
            required step,
            required stepNumber,
            required totalSteps,
            required progress,
            required title,
            required scrollController,
            required onBack,
            required onStage,
            required onPrev,
            required onNext,
          }) => _buildPageContent(
            step: step,
            stepNumber: stepNumber,
            totalSteps: totalSteps,
            progress: progress,
            title: title,
            scrollController: scrollController,
            onBack: onBack,
            onStage: onStage,
            onPrev: onPrev,
            onNext: onNext,
          ),
      overviewTransformationController: _overviewTransformationController,
      onOverviewInteractionStart: _handleOverviewInteractionStart,
      onOverviewInteractionUpdate: _handleOverviewPanUpdate,
      onOverviewInteractionEnd: _handleOverviewInteractionEnd,
      overviewPanEnabled: !_overviewGestureLock,
      overviewDragFriction: _overviewDragFriction,
      overviewMinScale: _overviewPreviewScale,
      overviewCanvasSize: _overviewCanvasSize(),
      overviewPages: _allOverviewPages,
      overviewCardSize: _overviewCardSize(),
      pagePositionFor: (page) => _getCardPosition(page.stepIndex),
      onPageTap: _handleOverviewCardTap,
      pageBuilder: (page) {
        final manifest = _manifest;
        if (manifest == null) return const SizedBox.shrink();
        final pageHeight = MediaQuery.sizeOf(context).height;
        final title = context.t(manifest.titleKey);
        return _buildOverviewPage(page, manifest, title, pageHeight);
      },
      currentStep: () => _currentStep!,
      clampedStepIndex: _clampedStepIndex,
      totalSteps: _totalSteps,
      scrollController: _scrollController,
      stageButtonKey: _stageButtonKey,
      progressKey: _progressKey,
      onboardingHighlightKey: _onboardingHighlightKey,
      popToHome: _popToHome,
      showStepSelector: _showStepSelector,
      prevStep: _prevStep,
      nextStep: _nextStep,
      closeOverviewMode: _closeOverviewMode,
      onOnboardingNext: _onOnboardingNext,
    );
  }
}
