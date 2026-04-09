import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../core/audio/ayah_audio.dart';
import '../../../core/audio/ayah_audio_controller.dart';
import '../../../core/text/transliteration_localizer.dart';
import '../../../core/widgets/pressable.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../../settings/language/data/language_repository_memory.dart';
import '../../settings/theme/presentation/theme_text_size_store.dart';
import '../../stage/parts/stage_bottom_button.dart';
import '../../stage/parts/stage_card.dart';
import '../../stage/parts/stage_progress_bar.dart';
import '../../stage/parts/stage_top_bar.dart';
import '../../quran/model/quran_ayah.dart';

class AblutionScreen extends StatefulWidget {
  const AblutionScreen({super.key});

  @override
  State<AblutionScreen> createState() => _AblutionScreenState();
}

class _AblutionScreenState extends State<AblutionScreen>
    with SingleTickerProviderStateMixin {
  static const double _blurShowOffset = 100;
  static const double _horizontalSwipeVelocityThreshold = 220;
  late final AyahAudio _audio;
  final GlobalKey _stageButtonKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  late final Future<_AblutionManifest> _manifestFuture;
  late final AnimationController _pageTransitionController;
  final Map<String, bool> _assetExistsMemo = {};

  _AblutionManifest? _manifest;
  int _stepIndex = 0;
  int _stepDirection = 1;
  int? _pendingStepIndex;
  bool _appliedPendingTransition = false;
  bool _showTopBlur = false;
  String? _playingStepAudioKey;

  @override
  void initState() {
    super.initState();
    _audio = AyahAudioController()..addListener(_onAudioTick);
    _scrollController.addListener(_handleScroll);
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _manifestFuture = _loadManifest();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioTick);
    unawaited(_audio.dispose());
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _onAudioTick() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleScroll() {
    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _blurShowOffset;
    if (shouldShow == _showTopBlur) return;
    setState(() => _showTopBlur = shouldShow);
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

  void _prevStep() {
    if (_totalSteps == 0) return;
    if (_clampedStepIndex > 0) {
      _animateStepTransitionTo(_clampedStepIndex - 1, direction: -1);
      return;
    }
    _stopAudioSilently();
    Navigator.of(context).maybePop();
  }

  void _nextStep() {
    if (_totalSteps == 0) return;
    if (_clampedStepIndex < _totalSteps - 1) {
      _animateStepTransitionTo(_clampedStepIndex + 1, direction: 1);
      return;
    }
    _stopAudioSilently();
    Navigator.of(context).maybePop();
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_pageTransitionController.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_horizontalSwipeVelocityThreshold) {
      _nextStep();
      return;
    }
    if (velocity >= _horizontalSwipeVelocityThreshold) {
      _prevStep();
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

  void _applyPendingTransition(int stepIndex) {
    if (_appliedPendingTransition) return;
    final clamped = stepIndex.clamp(0, _totalSteps - 1);
    _stopAudioSilently();
    setState(() => _stepIndex = clamped);
    _appliedPendingTransition = true;
  }

  Future<void> _animateStepTransitionTo(
    int stepIndex, {
    required int direction,
  }) async {
    if (_pageTransitionController.isAnimating) return;
    if (_totalSteps == 0) return;
    final nextStep = stepIndex.clamp(0, _totalSteps - 1);
    if (nextStep == _clampedStepIndex) return;

    _stepDirection = direction;
    _pendingStepIndex = nextStep;
    _appliedPendingTransition = false;

    await _pageTransitionController.forward(from: 0);
    if (!mounted) return;
    if (!_appliedPendingTransition) {
      _applyPendingTransition(nextStep);
    }
    _pendingStepIndex = null;
    _appliedPendingTransition = false;
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
    await _animateStepTransitionTo(
      next,
      direction: next > _clampedStepIndex ? 1 : -1,
    );
  }

  Widget _buildPageContent({
    required _AblutionStepManifest step,
    required int stepNumber,
    required int totalSteps,
    required double progress,
    required double cardTextSize,
    required String title,
    required double bottomInset,
    ScrollController? scrollController,
    required VoidCallback onBack,
    required VoidCallback onStage,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final colors = context.colors;
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12.h,
        bottom: 24.h + bottomInset,
      ),
      children: [
        StageTopBar(
          onBack: onBack,
          onStage: onStage,
          stageButtonKey: _stageButtonKey,
        ),
        SizedBox(height: 20.h),
        _AblutionProgressBlock(
          title: title,
          stepIndex: stepNumber,
          totalSteps: totalSteps,
          progress: progress.clamp(0.0, 1.0),
        ),
        SizedBox(height: 12.h),
        StageCard(
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
                    placeholderBuilder: (_) => SvgPicture.asset(
                      step.image,
                      width: 250.h,
                      fit: BoxFit.contain,
                    ),
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
        ],
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: StageBottomButton(
                variant: StageBottomButtonVariant.secondary,
                label: context.t('common.back'),
                icon: 'assets/icons/arrow-left.svg',
                onTap: onPrev,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StageBottomButton(
                variant: StageBottomButtonVariant.primary,
                label: context.t('common.next'),
                icon: 'assets/icons/arrow-right.svg',
                onTap: onNext,
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

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
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

              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: AnimatedBuilder(
                      animation: _pageTransitionController,
                      builder: (context, child) {
                        final targetStepIndex = _pendingStepIndex;
                        final isAnimating =
                            _pageTransitionController.isAnimating &&
                            targetStepIndex != null;
                        final screenWidth = MediaQuery.sizeOf(context).width;
                        final pageWidth = (screenWidth - 32.w).clamp(
                          0.0,
                          double.infinity,
                        );
                        final travelDistance = pageWidth + 32.w;
                        final animationProgress = Curves.easeInOutBack.transform(
                          _pageTransitionController.value.clamp(0.0, 1.0),
                        );
                        final currentPageDx = isAnimating
                            ? -_stepDirection * travelDistance * animationProgress
                            : 0.0;
                        final pendingPageDx =
                            currentPageDx + (_stepDirection * travelDistance);

                        final nextIndex = targetStepIndex == null
                            ? _clampedStepIndex
                            : targetStepIndex.clamp(0, _totalSteps - 1);
                        final pendingStep = manifest.steps[nextIndex];
                        final pendingStepNumber = nextIndex + 1;
                        final pendingProgress = pendingStepNumber / _totalSteps;

                        return IgnorePointer(
                          ignoring: isAnimating,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Transform.translate(
                                offset: Offset(currentPageDx, 0),
                                child: child,
                              ),
                              if (isAnimating)
                                Transform.translate(
                                  offset: Offset(pendingPageDx, 0),
                                  child: _buildPageContent(
                                    step: pendingStep,
                                    stepNumber: pendingStepNumber,
                                    totalSteps: _totalSteps,
                                    progress: pendingProgress,
                                    cardTextSize: cardTextSize,
                                    title: title,
                                    bottomInset: bottomInset,
                                    scrollController: null,
                                    onBack: () {},
                                    onStage: () {},
                                    onPrev: () {},
                                    onNext: () {},
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      child: _buildPageContent(
                        step: step,
                        stepNumber: stepNumber,
                        totalSteps: _totalSteps,
                        progress: progress,
                        cardTextSize: cardTextSize,
                        title: title,
                        bottomInset: bottomInset,
                        scrollController: _scrollController,
                        onBack: () => Navigator.of(context).maybePop(),
                        onStage: _showStepSelector,
                        onPrev: _prevStep,
                        onNext: _nextStep,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AppBlurredTopOverlay(visible: _showTopBlur),
                  ),
	                ],
	              );
            },
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
