import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/app_dependencies_scope.dart';
import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/ui_kit/app_button.dart';
import '../prayer/domain/entities/prayer_request_context.dart';
import '../prayer/domain/entities/prayer_rakaat.dart';
import '../prayer/domain/usecases/get_prayer_rakaats.dart';
import '../prayer/presentation/prayer_rakaats_controller.dart';
import '../settings/gender/data/gender_repository_memory.dart';
import '../settings/language/data/language_repository_memory.dart';
import '../settings/madhhab/data/madhhab_repository_memory.dart';
import 'models/rakaat_models.dart';
import 'stage_step_screen.dart';

class StageSplashScreen extends StatefulWidget {
  const StageSplashScreen({
    super.key,
    required this.prayerCode,
    required this.prayerTitle,
  });

  final String prayerCode;
  final String prayerTitle;

  @override
  State<StageSplashScreen> createState() => _StageSplashScreenState();
}

class _StageSplashScreenState extends State<StageSplashScreen> {
  PrayerRakaatsController? _controller;
  bool _navigated = false;
  late List<PrayerRequestContext> _contextFallbackChain;
  int _contextAttemptIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

    final repository = AppDependenciesScope.prayerRepositoryOf(context);
    _controller = PrayerRakaatsController(
      getPrayerRakaats: GetPrayerRakaats(repository),
    )..addListener(_onControllerChanged);

    _contextFallbackChain = _buildContextFallbackChain();
    _controller!.load(baseContext: _contextFallbackChain.first);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  PrayerRequestContext _contextForLanguage(String languageCode) {
    final script = switch (languageCode) {
      'ru' => 'cyrillic',
      _ => 'latin',
    };
    final genderCode = GenderRepositoryMemory.instance.getSelectedGender().id;
    final madhhabCode = MadhhabRepositoryMemory.instance
        .getSelectedMadhhab()
        .id;
    return PrayerRequestContext(
      prayerCode: widget.prayerCode,
      madhhabCode: madhhabCode,
      genderCode: genderCode,
      languageCode: languageCode,
      rakah: 1,
      script: script,
    );
  }

  List<PrayerRequestContext> _buildContextFallbackChain() {
    final selectedLanguageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    final languageCandidates = <String>[
      selectedLanguageCode,
      if (selectedLanguageCode != 'ru') 'ru',
      if (selectedLanguageCode != 'en') 'en',
    ];
    return languageCandidates.map(_contextForLanguage).toList(growable: false);
  }

  bool _isLanguageNotFoundError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('language not found');
  }

  void _onControllerChanged() {
    final state = _controller?.state;
    if (!mounted || state == null) return;

    if (state is PrayerRakaatsError && !_navigated) {
      final hasFallback =
          _contextAttemptIndex < _contextFallbackChain.length - 1;
      if (hasFallback && _isLanguageNotFoundError(state.message)) {
        _contextAttemptIndex += 1;
        _controller?.load(
          baseContext: _contextFallbackChain[_contextAttemptIndex],
        );
        return;
      }
    }

    if (state is PrayerRakaatsLoaded && !_navigated) {
      _navigated = true;
      final rakaats = _mapPrayerToStageRakaats(state.rakaats);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goNext(rakaats);
      });
      return;
    }

    setState(() {});
  }

  void _goNext(List<RakaatData> rakaats) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StageStepScreen(
              rakaats: rakaats,
              prayerTitle: widget.prayerTitle,
              prayerCode: widget.prayerCode,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = _controller?.state ?? const PrayerRakaatsInitial();

    final isLoading =
        state is PrayerRakaatsLoading || state is PrayerRakaatsInitial;
    final errorMessage = state is PrayerRakaatsError ? state.message : null;
    final shownError = _toDisplayError(context, errorMessage);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppRadii.card.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 4.h),
                if (isLoading) ...[
                  SizedBox(
                    width: 26.r,
                    height: 26.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.r,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  AppButton(
                    label: context.t('stage.splash.openDemo'),
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: () => _goNext(_demoRakaats()),
                  ),
                ] else ...[
                  Text(
                    context.t('stage.splash.failedLoad'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    shownError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  FilledButton(
                    onPressed: () {
                      setState(() => _navigated = false);
                      _contextAttemptIndex = 0;
                      _contextFallbackChain = _buildContextFallbackChain();
                      _controller?.load(
                        baseContext: _contextFallbackChain.first,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill.r),
                      ),
                    ),
                    child: Text(
                      context.t('common.retry'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: colors.card,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  AppButton(
                    label: context.t('stage.splash.openDemo'),
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: () => _goNext(_demoRakaats()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _toDisplayError(BuildContext context, String? message) {
    final value = (message ?? '').toLowerCase();
    if (value.contains('prayer_not_found') ||
        value.contains('нет данных для выбранного намаза')) {
      return context.t('errors.prayerNotFound');
    }
    if (value.isEmpty) return context.t('app.unknownError');
    return message!;
  }
}

List<RakaatData> _mapPrayerToStageRakaats(List<PrayerRakaat> rakaats) {
  return rakaats.map((r) {
    final steps = [...r.steps]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return RakaatData(
      number: r.context.rakah,
      imageAsset: r.context.rakah == 1
          ? 'assets/icons/salat-1.png'
          : 'assets/icons/salat.png',
      steps: steps
          .map(
            (s) => RakaatStep(
              orderIndex: s.orderIndex,
              title: _stageStepTitle(s.stepCode),
              movementDescription: s.content.movementDescription,
              arabic: s.content.recitationArabic,
              transliteration: s.content.transliteration,
              translation: s.content.translation,
              stepCode: s.stepCode,
            ),
          )
          .toList(),
    );
  }).toList();
}

String _stageStepTitle(String code) {
  final normalized = code.trim();
  if (normalized.isEmpty) {
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    return languageCode == 'ru' ? 'Шаг' : 'Step';
  }
  final parts = normalized
      .split(RegExp(r'[_\-\s]+'))
      .where((p) => p.isNotEmpty);
  return parts
      .map(
        (p) => p.length <= 1
            ? p.toUpperCase()
            : '${p[0].toUpperCase()}${p.substring(1)}',
      )
      .join(' ');
}

extension on _StageSplashScreenState {
  List<RakaatData> _demoRakaats() {
    final total = switch (widget.prayerCode) {
      'fajr' => 2,
      'maghrib' => 3,
      'dhuhr' || 'asr' || 'isha' => 4,
      _ => 2,
    };

    final localizedSteps = [
      RakaatStep(
        orderIndex: 1,
        title: context.t('stage.demo.takbir.title'),
        movementDescription: context.t('stage.demo.takbir.description'),
        arabic: 'اللّٰهُ أَكْبَرُ',
        transliteration: context.t('stage.demo.takbir.transliteration'),
        translation: context.t('stage.demo.takbir.translation'),
        stepCode: 'takbir',
        audioUrl: 'assets/audio/takbir.mp3',
      ),
      RakaatStep(
        orderIndex: 2,
        title: context.t('stage.demo.istiadha.title'),
        movementDescription: context.t('stage.demo.istiadha.description'),
        arabic: 'أﻋُﻮذُ بِاللَّهِ ﻣِﻦَ اﻟﺸَّﻴْﻄَﺎن اﻟﺮَّﺟِﻴﻢ',
        transliteration: context.t('stage.demo.istiadha.transliteration'),
        translation: context.t('stage.demo.istiadha.translation'),
        stepCode: 'istiadha',
        audioUrl: 'assets/audio/istiaza.mp3',
      ),
    ];

    return List.generate(
      total,
      (i) => RakaatData(
        number: i + 1,
        imageAsset: i == 0
            ? 'assets/icons/salat-1.png'
            : 'assets/icons/salat.png',
        steps: localizedSteps,
      ),
    );
  }
}
