import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/ui_kit/app_button.dart';
import '../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../core/audio/ayah_audio.dart';
import '../../../core/audio/ayah_audio_controller.dart';
import '../../../core/text/transliteration_localizer.dart';
import '../../../core/widgets/pressable.dart';
import '../../onboarding/data/onboarding_repository_memory.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../../settings/language/data/language_repository_memory.dart';
import '../../settings/theme/presentation/theme_text_size_store.dart';
import '../../stage/parts/stage_bottom_button.dart';
import '../../stage/parts/stage_card.dart';
import '../../stage/parts/stage_progress_bar.dart';
import '../../stage/parts/stage_top_bar.dart';
import '../../stage/stage_onboarding_overlay.dart';
import '../../quran/model/quran_ayah.dart';

class AblutionScreen extends StatefulWidget {
  const AblutionScreen({super.key});

  @override
  State<AblutionScreen> createState() => _AblutionScreenState();
}

class _AblutionScreenState extends State<AblutionScreen>
    with SingleTickerProviderStateMixin {
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
  late final Future<_AblutionManifest> _manifestFuture;
  final Map<String, bool> _assetExistsMemo = {};

  _AblutionManifest? _manifest;
  int _stepIndex = 0;
  String? _playingStepAudioKey;
  int _lightTransitionToken = 0;
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
    _showOnboarding = OnboardingRepositoryMemory.instance.consumeStageOnboarding();
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

  Future<_AblutionManifest> _loadManifest() async {
    final raw = await rootBundle.loadString('assets/ablution/ablution.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _AblutionManifest.fromJson(json);
  }

  int get _totalSteps => _manifest?.steps.length ?? 0;

  int get _clampedStepIndex {
    final total = _totalSteps;
    if (total == 0) return 0;
    return _stepIndex.clamp(0, total - 1);
  }

  _AblutionStepManifest? get _currentStep {
    if (_manifest == null || _manifest!.steps.isEmpty) return null;
    return _manifest!.steps[_clampedStepIndex];
  }

  String _audioStepKey(_AblutionStepManifest step) =>
      'ablution-step-${step.id}';

  bool _isStepAudioPlaying(_AblutionStepManifest step) =>
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

  Future<String> _resolveStepAudioAsset(_AblutionStepManifest step) async {
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

  String _stepImageAsset(_AblutionStepManifest step) {
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
    _AblutionStepManifest step,
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

  Future<void> _toggleStepAyahAudio(_AblutionStepManifest step) async {
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

  String _localizedStepTransliteration(_AblutionStepManifest step) {
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
        _lightTransitionToken++;
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
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
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
                        context.t('ablution.selectSection'),
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
                          borderRadius: BorderRadius.circular(AppRadii.circle),
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
                SizedBox(height: 14.h),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: manifest.steps.length,
                    separatorBuilder: (context, index) =>
                        Container(height: 1, color: colors.divider),
                    itemBuilder: (context, index) {
                      final step = manifest.steps[index];
                      return Pressable(
                        onTap: () => Navigator.of(context).pop(index),
                        borderRadius: BorderRadius.circular(AppRadii.inner.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 20.h,
                            horizontal: 2.w,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.t(step.titleKey),
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

    if (!mounted || selected == null) return;
    final next = selected.clamp(0, _totalSteps - 1);
    if (next == _clampedStepIndex) return;
    await _selectStepIndex(next, direction: next >= _clampedStepIndex ? 1 : -1);
  }

  Widget _animateStepTransition(Widget child) {
    return child;
  }

  List<_AblutionOverviewPageReference> get _allOverviewPages {
    final total = _totalSteps;
    if (total <= 0) return const [];
    return List<_AblutionOverviewPageReference>.generate(
      total,
      (index) => _AblutionOverviewPageReference(stepIndex: index),
      growable: false,
    );
  }

  int get _currentFlatPageIndex {
    final pages = _allOverviewPages;
    if (pages.isEmpty) return 0;
    return _clampedStepIndex.clamp(0, pages.length - 1);
  }

  _AblutionOverviewPageReference? _pageForFlatIndex(int flatIndex) {
    final pages = _allOverviewPages;
    if (pages.isEmpty) return null;
    return pages[flatIndex.clamp(0, pages.length - 1)];
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

  Offset _getCardPosition(int flatIndex) {
    final size = _overviewCardSize();
    final x =
        _overviewCanvasInset + flatIndex * (size.width + _overviewPageGap);
    final y = _overviewCanvasInset;
    return Offset(x, y);
  }

  Rect _overviewContentRect() {
    final size = _overviewCardSize();
    final pageCount = math.max(_allOverviewPages.length, 1);
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

  Rect _overviewCardRect(_AblutionOverviewPageReference page) {
    final size = _overviewCardSize();
    final position = _getCardPosition(page.stepIndex);
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  Matrix4 _overviewMatrixForPage(
    _AblutionOverviewPageReference page, {
    double scale = 1,
  }) {
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
    final clamped = _clampOverviewTransform(
      _overviewTransformationController.value,
    );
    final current = _overviewTransformationController.value;
    if (_matricesAreEqual(current, clamped)) return;
    _isClampingOverviewTransform = true;
    _overviewTransformationController.value = clamped;
    _isClampingOverviewTransform = false;
  }

  Matrix4 _clampOverviewTransform(Matrix4 matrix) {
    final rect = _overviewContentRect();
    final next = Matrix4.copy(matrix);
    final scale = next.storage[0].clamp(_overviewPreviewScale, 1.0).toDouble();
    final viewport = _overviewViewportSize();
    final minDx = viewport.width - _overviewFitPadding - (rect.right * scale);
    final maxDx = _overviewFitPadding - (rect.left * scale);
    final rawDx = next.storage[12];
    final clampedDx = rawDx.clamp(minDx, maxDx).toDouble();
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

  int _nearestFlatIndexFromCurrentTransform() {
    final pages = _allOverviewPages;
    if (pages.isEmpty) return 0;
    final viewport = _overviewViewportSize();
    final matrix = _overviewTransformationController.value;
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
    final pages = _allOverviewPages;
    if (pages.isEmpty) return 0;
    final matrix = _overviewTransformationController.value;
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
    _overviewTransformationController.value = _clampOverviewTransform(boosted);
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
    _AblutionOverviewPageReference page,
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

  Widget _buildOverviewPage({
    required _AblutionOverviewPageReference page,
    required _AblutionManifest manifest,
    required String title,
    required double cardTextSize,
    required double pageHeight,
  }) {
    final colors = context.colors;
    final pageId = page.stepIndex;
    final pageScrollController = _overviewScrollControllerFor(pageId);
    if (!_overviewOverflowByPage.containsKey(pageId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !pageScrollController.hasClients) return;
        _setOverviewOverflow(
          pageId,
          pageScrollController.position.maxScrollExtent > 0.5,
        );
      });
    }
    final step = manifest.steps[page.stepIndex];
    final stepNumber = page.stepIndex + 1;
    final progress = stepNumber / math.max(manifest.steps.length, 1);
    return SizedBox(
      height: pageHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
                NotificationListener<ScrollMetricsNotification>(
                  onNotification: (notification) {
                    _setOverviewOverflow(
                      pageId,
                      notification.metrics.maxScrollExtent > 0.5,
                    );
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: pageScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 21.h,
                      bottom: 20.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AblutionProgressBlock(
                          title: title,
                          stepIndex: stepNumber,
                          totalSteps: manifest.steps.length,
                          progress: progress,
                        ),
                        SizedBox(height: 12.h),
                        StageCard(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  child: SvgPicture.asset(
                                    _stepImageAsset(step),
                                    width: 250.h,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (_) =>
                                        SizedBox(width: 250.h, height: 250.h),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                context.t(step.titleKey),
                                style: TextStyle(
                                  fontSize: cardTextSize.sp,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                context.t(step.descriptionKey),
                                style: TextStyle(
                                  fontSize: cardTextSize.sp,
                                  height: 1.48,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (step.text != null) ...[
                          SizedBox(height: 12.h),
                          StageCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.soft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.inner.r,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 26.w,
                                        height: 26.w,
                                        child: Center(
                                          child: SvgPicture.asset(
                                            'assets/icons/play.svg',
                                            colorFilter: ColorFilter.mode(
                                              colors.primary,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          step.text!.arabic,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          textScaler: TextScaler.noScaling,
                                          style: TextStyle(
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.w500,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  _localizedStepTransliteration(step),
                                  style: TextStyle(
                                    fontSize: cardTextSize.sp,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  context.t(step.text!.translationKey),
                                  style: TextStyle(
                                    fontSize: cardTextSize.sp,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewLayer({
    required _AblutionManifest manifest,
    required String title,
    required double cardTextSize,
  }) {
    final pages = _allOverviewPages;
    final pageHeight = MediaQuery.sizeOf(context).height;
    final cardSize = _overviewCardSize();
    final canvasSize = _overviewCanvasSize();
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: context.colors.background,
      child: InteractiveViewer(
        transformationController: _overviewTransformationController,
        onInteractionStart: _handleOverviewInteractionStart,
        onInteractionUpdate: _handleOverviewPanUpdate,
        onInteractionEnd: _handleOverviewInteractionEnd,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        constrained: false,
        panEnabled: !_overviewGestureLock,
        scaleEnabled: !_overviewGestureLock,
        panAxis: PanAxis.horizontal,
        interactionEndFrictionCoefficient: _overviewDragFriction,
        minScale: _overviewPreviewScale,
        maxScale: 1,
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            children: [
              for (final page in pages)
                () {
                  final position = _getCardPosition(page.stepIndex);
                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    width: cardSize.width,
                    height: cardSize.height,
                    child: RepaintBoundary(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => unawaited(_handleOverviewCardTap(page)),
                        child: IgnorePointer(
                          ignoring: true,
                          child: _buildOverviewPage(
                            page: page,
                            manifest: manifest,
                            title: title,
                            cardTextSize: cardTextSize,
                            pageHeight: pageHeight,
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

  Widget _buildPageContent({
    required _AblutionStepManifest step,
    required int stepNumber,
    required int totalSteps,
    required double progress,
    required double cardTextSize,
    required String title,
    required double topContentPadding,
    required double bottomInset,
    ScrollController? scrollController,
    required VoidCallback onBack,
    required VoidCallback onStage,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final colors = context.colors;
    final hasPrevStep = stepNumber > 1;
    final hasNextStep = stepNumber < totalSteps;
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: topContentPadding,
        bottom: 24.h + bottomInset,
      ),
      children: [
        IgnorePointer(
          ignoring: !_showTopControls,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            scale: _showTopControls ? 1 : 0.9,
            alignment: Alignment.center,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              opacity: _showTopControls ? 1 : 0,
              child: StageTopBar(
                onBack: onBack,
                onStage: onStage,
                stageButtonKey: _stageButtonKey,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        KeyedSubtree(
          key: _progressKey,
          child: Pressable(
            onTap: _openOverviewMode,
            borderRadius: BorderRadius.circular(AppRadii.card.r),
            child: _AblutionProgressBlock(
              title: title,
              stepIndex: stepNumber,
              totalSteps: totalSteps,
              progress: progress.clamp(0.0, 1.0),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        (step.text == null)
            ? KeyedSubtree(
                key: _onboardingHighlightKey,
                child: StageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 260.h,
                        decoration: BoxDecoration(
                          color: colors.soft,
                          borderRadius: BorderRadius.circular(AppRadii.inner.r),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            _stepImageAsset(step),
                            width: 250.h,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) =>
                                SizedBox(width: 250.h, height: 250.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        context.t(step.titleKey),
                        style: TextStyle(
                          fontSize: cardTextSize.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        context.t(step.descriptionKey),
                        style: TextStyle(
                          fontSize: cardTextSize.sp,
                          height: 1.48,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : StageCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 260.h,
                  decoration: BoxDecoration(
                    color: colors.soft,
                    borderRadius: BorderRadius.circular(AppRadii.inner.r),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      _stepImageAsset(step),
                      width: 250.h,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) =>
                          SizedBox(width: 250.h, height: 250.h),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  context.t(step.titleKey),
                  style: TextStyle(
                    fontSize: cardTextSize.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  context.t(step.descriptionKey),
                  style: TextStyle(
                    fontSize: cardTextSize.sp,
                    height: 1.48,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (step.text != null) ...[
          SizedBox(height: 12.h),
          Pressable(
            onTap: () => _toggleStepAyahAudio(step),
            borderRadius: BorderRadius.circular(AppRadii.card.r),
            child: KeyedSubtree(
              key: _onboardingHighlightKey,
              child: StageCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: BorderRadius.circular(AppRadii.inner.r),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26.w,
                            height: 26.w,
                            child: Center(
                              child: SvgPicture.asset(
                                _isStepAudioPlaying(step)
                                    ? 'assets/icons/pause.svg'
                                    : 'assets/icons/play.svg',
                                colorFilter: ColorFilter.mode(
                                  colors.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              step.text!.arabic,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      _localizedStepTransliteration(step),
                      style: TextStyle(
                        fontSize: cardTextSize.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      context.t(step.text!.translationKey),
                      style: TextStyle(
                        fontSize: cardTextSize.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                opacity: hasPrevStep ? 1 : 0.5,
                child: StageBottomButton(
                  variant: StageBottomButtonVariant.secondary,
                  label: context.t('common.back'),
                  icon: 'assets/icons/arrow-left.svg',
                  onTap: hasPrevStep ? onPrev : null,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                opacity: hasNextStep ? 1 : 0.5,
                child: StageBottomButton(
                  variant: StageBottomButtonVariant.primary,
                  label: context.t('common.next'),
                  icon: 'assets/icons/arrow-right.svg',
                  onTap: hasNextStep ? onNext : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final cardTextSize = ThemeTextSizeStore.textSize;
    final topControlInset = _overviewRestingTopInset();

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
            child: FutureBuilder<_AblutionManifest>(
              future: _manifestFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(
                    child: Text(
                      context.t('app.loading'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        context.t('errors.failedLoadAblution'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }

                _manifest ??= snapshot.data!;
                final manifest = _manifest!;
                if (manifest.steps.isEmpty) {
                  return Center(
                    child: Text(
                      context.t('errors.failedLoadAblution'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  );
                }

                final step = _currentStep!;
                final stepNumber = _clampedStepIndex + 1;
                final progress = stepNumber / _totalSteps;
                final title = context.t(manifest.titleKey);

                return AppBlurredTopOverlay(
                  visible: _showTopBlur && !_showOverviewLayer,
                  height: 150,
                  maxBlurSigma: 60,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        ignoring: _showOverviewLayer,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: _animateStepTransition(
                            _buildPageContent(
                              step: step,
                              stepNumber: stepNumber,
                              totalSteps: _totalSteps,
                              progress: progress,
                              cardTextSize: cardTextSize,
                              title: title,
                              topContentPadding: topControlInset,
                              bottomInset: bottomInset,
                              scrollController: _scrollController,
                              onBack: () => unawaited(_popToHome()),
                              onStage: _showStepSelector,
                              onPrev: () => unawaited(_prevStep()),
                              onNext: () => unawaited(_nextStep()),
                            ),
                          ),
                        ),
                      ),
                      if (_showOverviewLayer)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _isOverviewClosing,
                            child: _buildOverviewLayer(
                              manifest: manifest,
                              title: title,
                              cardTextSize: cardTextSize,
                            ),
                          ),
                        ),
                      if (_showOverviewExitButton)
                        Positioned(
                          left: 16.w,
                          right: 16.w,
                        bottom: MediaQuery.paddingOf(context).bottom + 24.h,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.inner.r),
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
                      if (_showOnboarding && !_showOverviewLayer)
                        Positioned.fill(
                          key: const ValueKey('ablution_onboarding_overlay'),
                          child: IgnorePointer(
                            ignoring: false,
                            child: StageOnboardingOverlay(
                              key: const ValueKey(
                                'ablution_onboarding_overlay_content',
                              ),
                              stageButtonKey: _stageButtonKey,
                              progressCardKey: _progressKey,
                              selectedAyahCardKey: _onboardingHighlightKey,
                              scrollController: _scrollController,
                              stepIndex: _onboardingStepIndex,
                              onNext: _onOnboardingNext,
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
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AblutionProgressBlock extends StatelessWidget {
  const _AblutionProgressBlock({
    required this.title,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
  });

  final String title;
  final int stepIndex;
  final int totalSteps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            context.t(
              'ablution.progressSteps',
              namedArgs: {'current': '$stepIndex', 'total': '$totalSteps'},
            ),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colors.secondary,
            ),
          ),
          SizedBox(height: 12.h),
          StageProgressBar(value: progress, animate: false),
        ],
      ),
    );
  }
}

class _AblutionManifest {
  const _AblutionManifest({
    required this.titleKey,
    required this.descriptionKey,
    required this.steps,
  });

  factory _AblutionManifest.fromJson(Map<String, dynamic> json) {
    final rawSteps = (json['steps'] as List<dynamic>? ?? const []);
    return _AblutionManifest(
      titleKey: json['title_key'] as String? ?? 'ablution.title',
      descriptionKey: json['description_key'] as String? ?? '',
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(_AblutionStepManifest.fromJson)
          .toList(growable: false),
    );
  }

  final String titleKey;
  final String descriptionKey;
  final List<_AblutionStepManifest> steps;
}

class _AblutionStepManifest {
  const _AblutionStepManifest({
    required this.id,
    required this.image,
    required this.audio,
    required this.titleKey,
    required this.descriptionKey,
    this.text,
  });

  factory _AblutionStepManifest.fromJson(Map<String, dynamic> json) {
    return _AblutionStepManifest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      image: json['image'] as String? ?? '',
      audio: json['audio'] as String? ?? '',
      titleKey: json['title_key'] as String? ?? '',
      descriptionKey: json['description_key'] as String? ?? '',
      text: _AblutionStepTextManifest.fromJson(
        json['text'] as Map<String, dynamic>?,
      ),
    );
  }

  final int id;
  final String image;
  final String audio;
  final String titleKey;
  final String descriptionKey;
  final _AblutionStepTextManifest? text;
}

class _AblutionStepTextManifest {
  const _AblutionStepTextManifest({
    required this.arabic,
    required this.transliteration,
    required this.translationKey,
  });

  static _AblutionStepTextManifest? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return _AblutionStepTextManifest(
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translationKey: json['translation_key'] as String? ?? '',
    );
  }

  final String arabic;
  final String transliteration;
  final String translationKey;
}

class _AblutionOverviewPageReference {
  const _AblutionOverviewPageReference({required this.stepIndex});

  final int stepIndex;
}
