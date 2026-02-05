import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../core/audio/ayah_audio.dart';
import '../../core/audio/ayah_audio_controller.dart';
import '../../core/widgets/pressable.dart';
import 'models/rakaat_models.dart';
import '../quran/model/quran_ayah.dart';

part 'parts/stage_ayah_card.dart';
part 'parts/stage_bottom_button.dart';
part 'parts/stage_card.dart';
part 'parts/stage_pinned_progress.dart';
part 'parts/stage_progress_bar.dart';
part 'parts/stage_stage_item.dart';
part 'parts/stage_top_bar.dart';

class StageStepScreen extends StatefulWidget {
  const StageStepScreen({super.key, required this.rakaats, this.audio});

  final List<RakaatData> rakaats;
  final AyahAudio? audio;

  @override
  State<StageStepScreen> createState() => _StageStepScreenState();
}

class _StageStepScreenState extends State<StageStepScreen> {
  late final AyahAudio _audio;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _stepKeys = {};
  final GlobalKey _progressKey = GlobalKey();
  bool _showPinned = false;

  String? _error;
  late List<RakaatData> _rakaats;
  int _rakaatIndex = 0;
  int _stepIndex = 0;
  bool _autoplayEnabled = false;
  String? _playingStepKey;
  String? _completedStepKey;
  bool _handlingCompletion = false;
  bool _contentAppeared = false;
  int _rakaatDirection = -1;
  bool _lastIsPlaying = false;

  @override
  void initState() {
    super.initState();
    _rakaats = widget.rakaats;
    _audio = widget.audio ?? AyahAudioController();
    _audio.addListener(_onAudioTick);
    if (_currentStep?.hasAudio ?? false) {
      _audio.setAyah(_stepToAyah(_currentStep!, _stepKey));
    }
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updatePinned();
      setState(() => _contentAppeared = true);
    });
  }

  void _onAudioTick() {
    final stepKey = _stepKey;
    final isPlaying = _audio.isPlaying;
    final progress = _audio.progress;
    final reachedEnd = progress >= 0.98;
    final completedByProgress =
        !isPlaying && _lastIsPlaying && reachedEnd;
    final isCompleted = _audio.isCompleted || completedByProgress;
    if (_currentStep != null &&
        _autoplayEnabled &&
        isCompleted &&
        _playingStepKey == stepKey &&
        _completedStepKey != stepKey &&
        !_handlingCompletion) {
      _completedStepKey = stepKey;
      _handlingCompletion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _advanceAndPlayNextStep();
        } finally {
          _handlingCompletion = false;
        }
      });
    }
    _lastIsPlaying = isPlaying;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioTick);
    _audio.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() => _updatePinned();

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

  List<RakaatStep> get _currentSteps => _currentRakaat?.steps ?? const [];

  RakaatStep? get _currentStep => _currentSteps.isEmpty
      ? null
      : _currentSteps[_stepIndex.clamp(0, _currentSteps.length - 1)];

  String get _stepKey => 'r$_rakaatIndex-s$_stepIndex';

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
      audioUrl: step.audioUrl,
    );
  }

  Future<void> _togglePlay() async {
    final step = _currentStep;
    if (step == null || !step.hasAudio) return;
    try {
      if (_audio.isPlaying) {
        _autoplayEnabled = false;
        _playingStepKey = null;
        await _audio.pause();
      } else {
        _autoplayEnabled = true;
        await _audio.setAyah(_stepToAyah(step, _stepKey));
        await _playCurrent();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _playCurrent() async {
    final step = _currentStep;
    if (step == null || !step.hasAudio) return;
    _playingStepKey = _stepKey;
    _completedStepKey = null;
    await _audio.play();
  }

  Future<void> _playStepAt(int index) async {
    if (_currentSteps.isEmpty) return;
    try {
      _autoplayEnabled = true;
      await _selectStep(index, playIfAutoplay: false);
      if (_currentStep?.hasAudio ?? false) {
        await _playCurrent();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _selectStep(int index, {bool playIfAutoplay = true}) async {
    if (_currentSteps.isEmpty) return;
    final next = index.clamp(0, _currentSteps.length - 1);
    setState(() => _stepIndex = next);
    final step = _currentStep;
    if (step == null) return;
    if (step.hasAudio) {
      await _audio.setAyah(_stepToAyah(step, _stepKey));
    }
    _playingStepKey = null;
    _completedStepKey = null;
    _scrollToStep(next);
    if (playIfAutoplay && _autoplayEnabled && step.hasAudio) {
      await _playCurrent();
    }
  }

  void _scrollToStep(int index) {
    if (index < 0 || index >= _currentSteps.length) return;
    final key = 'r$_rakaatIndex-s$index';
    final ctx = _stepKeys[key]?.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    });
  }

  Widget _animateAppear(Widget child, {double offsetY = 0.04}) {
    return AnimatedOpacity(
      opacity: _contentAppeared ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _animateRakaat(Widget child) {
    final dir = _rakaatDirection >= 0 ? 1.0 : -1.0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: Offset(0.08 * dir, 0),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (current, previous) =>
          current ?? const SizedBox.shrink(),
      child: KeyedSubtree(
        key: ValueKey('rakaat_$_rakaatIndex'),
        child: child,
      ),
    );
  }

  Future<void> _advanceAndPlayNextStep() async {
    if (_currentSteps.isEmpty) return;
    final isLast = _stepIndex >= _currentSteps.length - 1;
    if (isLast) {
      _autoplayEnabled = false;
      _playingStepKey = null;
      return;
    }
    await _selectStep(_stepIndex + 1, playIfAutoplay: true);
  }

  Future<void> _nextRakaat() async {
    if (_rakaats.isEmpty) return;
    final next = (_rakaatIndex + 1).clamp(0, _rakaats.length - 1);
    if (next == _rakaatIndex) return;
    setState(() {
      _rakaatDirection = 1;
      _rakaatIndex = next;
      _stepIndex = 0;
    });
    if (_currentStep?.hasAudio ?? false) {
      await _audio.setAyah(_stepToAyah(_currentStep!, _stepKey));
    }
    _scrollToStep(0);
  }

  Future<void> _prevRakaat() async {
    if (_rakaats.isNotEmpty && _rakaatIndex > 0) {
      setState(() {
        _rakaatDirection = -1;
        _rakaatIndex = _rakaatIndex - 1;
        _stepIndex = 0;
      });
      if (_currentStep?.hasAudio ?? false) {
        await _audio.setAyah(_stepToAyah(_currentStep!, _stepKey));
      }
      _scrollToStep(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRakaats = _rakaats.isEmpty ? 2 : _rakaats.length;
    final rakaatIndex = (_rakaats.isEmpty ? 0 : _rakaatIndex) + 1;
    final totalSteps = _currentSteps.isEmpty ? 1 : _currentSteps.length;
    final stepIndex = (_currentSteps.isEmpty ? 0 : _stepIndex) + 1;
    final stepProgress = totalSteps == 0 ? 0.0 : (stepIndex / totalSteps);
    final audioProgress = _audio.progress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
  bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 120.h, top: 60.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 12.h),
                    _TopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                      onStage: () => _showStageSheet(context),
                    ),
                    SizedBox(height: 12.h),
                    _animateAppear(
                      KeyedSubtree(
                        key: _progressKey,
                        child: _StageProgressBlock(
                          title: 'Al-Fajr',
                          rakaatIndex: rakaatIndex,
                          totalRakaats: totalRakaats,
                          stepIndex: stepIndex,
                          totalSteps: totalSteps,
                          progress: stepProgress.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _animateRakaat(
                      _animateAppear(
                        _Card(
                          child: Column(
                            children: [
                              Container(
                                height: 240.h,
                                decoration: BoxDecoration(
                                  color: AppColors.soft,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.inner.r,
                                  ),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    _currentRakaat?.imageAsset ??
                                        'assets/icons/salat.png',
                                    height: 205.h,
                                  ),
                                ),
                              ),
                              SizedBox(height: 25.h),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Takbir',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      height: 1,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                   'Standing, he directs his gaze to the spot where his forehead will touch during prostration, raises his hands to the level of his ears or shoulders and says:',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      height: 1.48,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
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
                    _animateRakaat(
                      _animateAppear(
                        Column(
                          children: [
                            for (var i = 0; i < _currentSteps.length; i++) ...[
                              KeyedSubtree(
                                key: _stepKeys.putIfAbsent(
                                  'r$_rakaatIndex-s$i',
                                  () => GlobalKey(),
                                ),
                                child: _AyahCard(
                                  ayahIndex: i,
                                  ayah: _currentSteps[i],
                                  selected: i == _stepIndex,
                                  isPlaying: (i == _stepIndex) &&
                                      _audio.isPlaying,
                                  progress: (i == _stepIndex)
                                      ? audioProgress.clamp(0.0, 1.0)
                                      : 0.0,
                                  onTap: () => _playStepAt(i),
                                  onPlayPause: () {
                                    if (i == _stepIndex) {
                                      _togglePlay();
                                    } else {
                                      _playStepAt(i);
                                    }
                                  },
                                ),
                              ),
                              if (i != _currentSteps.length - 1)
                                SizedBox(height: 16.h),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: 12.h),
                      _Card(
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
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20.w,
              right: 20.w,
              top: 64.h,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _showPinned ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_showPinned,
                  child: _PinnedProgressCard(
                    rakaatIndex: rakaatIndex,
                    totalRakaats: totalRakaats,
                    stepIndex: stepIndex,
                    totalSteps: totalSteps,
                    progress: stepProgress.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 18.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _BottomButton(
                          variant: _BottomButtonVariant.secondary,
                          label: 'Back',
                          icon: 'assets/icons/arrow-left.svg',
                          onTap: _prevRakaat,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 4,
                        child: _BottomButton(
                          variant: _BottomButtonVariant.primary,
                          label: 'Next',
                          icon: 'assets/icons/arrow-right.svg',
                          onTap: _nextRakaat,
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
    );
  }

  Future<void> _showStageSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16.r),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select a stage',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 12.h),
              _StageItem(title: 'Fajr', subtitle: '2 rakats • 2 steps'),
              _StageItem(title: 'Dhuhr', subtitle: '4 rakats • 4 steps'),
              _StageItem(title: 'Asr', subtitle: '4 rakats • 4 steps'),
              _StageItem(title: 'Maghrib', subtitle: '3 rakats • 3 steps'),
              _StageItem(title: 'Isha', subtitle: '4 rakats • 4 steps'),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}
