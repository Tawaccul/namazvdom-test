import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../app/app_dependencies_scope.dart';
import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../core/audio/ayah_audio.dart';
import '../../core/audio/ayah_audio_controller.dart';
import '../../core/widgets/pressable.dart';
import '../onboarding/data/onboarding_repository_memory.dart';
import '../prayer/domain/usecases/get_prayer_surah.dart';
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
  static const bool _alwaysShowStageOnboarding = true;

  late final AyahAudio _audio;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pageTransitionController;
  final GlobalKey _transitionStageButtonKey = GlobalKey();
  final Map<String, GlobalKey> _stepKeys = {};
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _stageButtonKey = GlobalKey();
  bool _showPinned = false;
  bool _showOnboarding = false;

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
  int _selectedAyahIndex = 0;
  int? _pendingRakaatIndex;
  int? _pendingStepIndex;
  bool _pendingJumpTop = false;
  bool _appliedPendingTransition = false;
  String? _selectedAdditionalSurahCode;
  final Map<String, bool> _assetExistsMemo = {};

  @override
  void initState() {
    super.initState();
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpToTop();
      _updatePinned();
      setState(() => _contentAppeared = true);
    });
  }

  void _onAudioTick() {
    final stepKey = _stepKey;
    final isPlaying = _audio.isPlaying;
    final progress = _audio.progress;
    final reachedEnd = progress >= 0.98;
    final completedByProgress = !isPlaying && _lastIsPlaying && reachedEnd;
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
                transliteration: ayah.transliteration,
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
        final transliteration = (map['transliteration'] as String? ?? '')
            .trim();
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

  void _applyPendingTransition(int rakaatIndex, int stepIndex) {
    if (_appliedPendingTransition) return;
    final stepCount = _stepCountForRakaat(rakaatIndex);
    final clampedStep = stepCount == 0 ? 0 : stepIndex.clamp(0, stepCount - 1);
    setState(() {
      _rakaatIndex = rakaatIndex;
      _stepIndex = clampedStep;
      _selectedAyahIndex = 0;
    });
    _appliedPendingTransition = true;
    if (_selectedAyahStep?.hasAudio ?? false) {
      _audio.setAyah(_stepToAyah(_selectedAyahStep!, _stepKey));
    }
    if (_pendingJumpTop) {
      _jumpToTop();
    }
  }

  void _jumpToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioTick);
    _audio.dispose();
    _pageTransitionController.dispose();
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
    final step = _selectedAyahStep;
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
    final step = _selectedAyahStep;
    if (step == null || !step.hasAudio) return;
    _playingStepKey = _stepKey;
    _completedStepKey = null;
    await _audio.play();
  }

  Future<void> _playStepAt(int ayahIndex) async {
    if (_currentRecitationEntries.isEmpty) return;
    try {
      _autoplayEnabled = true;
      await _selectAyahInCurrentStep(ayahIndex, playIfAutoplay: false);
      if (_selectedAyahStep?.hasAudio ?? false) {
        await _playCurrent();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
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
    _completedStepKey = null;
    _scrollToCurrentAyah();
    if (playIfAutoplay && _autoplayEnabled && step.hasAudio) {
      await _playCurrent();
    }
  }

  Future<void> _selectStep(int index, {bool playIfAutoplay = true}) async {
    if (_currentStepOrderIndexes.isEmpty) return;
    final next = index.clamp(0, _currentStepOrderIndexes.length - 1);
    setState(() {
      _stepIndex = next;
      _selectedAyahIndex = 0;
    });
    final step = _selectedAyahStep;
    if (step == null) return;
    if (step.hasAudio) {
      await _audio.setAyah(_stepToAyah(step, _stepKey));
    }
    _playingStepKey = null;
    _completedStepKey = null;
    _scrollToCurrentAyah();
    if (playIfAutoplay && _autoplayEnabled && step.hasAudio) {
      await _playCurrent();
    }
  }

  void _scrollToCurrentAyah() {
    final ctx = _stepKeys[_entryKey(_clampedAyahIndex)]?.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 920),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
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

  int _clampedStepIndexForRakaatIndex(int rakaatIndex, int stepIndex) {
    final orderIndexes = _stepOrderIndexesForRakaatIndex(rakaatIndex);
    if (orderIndexes.isEmpty) return 0;
    return stepIndex.clamp(0, orderIndexes.length - 1);
  }

  int? _stepOrderIndexFor(int rakaatIndex, int stepIndex) {
    final orderIndexes = _stepOrderIndexesForRakaatIndex(rakaatIndex);
    if (orderIndexes.isEmpty) return null;
    final clampedStep = _clampedStepIndexForRakaatIndex(rakaatIndex, stepIndex);
    return orderIndexes[clampedStep];
  }

  List<RakaatStep> _stepEntriesFor({
    required int rakaatIndex,
    required int stepIndex,
  }) {
    if (_rakaats.isEmpty) return const [];
    final normalized = rakaatIndex.clamp(0, _rakaats.length - 1);
    final orderIndex = _stepOrderIndexFor(normalized, stepIndex);
    if (orderIndex == null) return const [];
    return _rakaats[normalized].steps
        .where((step) => step.orderIndex == orderIndex)
        .toList(growable: false);
  }

  List<RakaatStep> _recitationEntriesFor({
    required int rakaatIndex,
    required int stepIndex,
  }) {
    return _stepEntriesFor(rakaatIndex: rakaatIndex, stepIndex: stepIndex)
        .where(
          (step) =>
              step.arabic.trim().isNotEmpty ||
              step.transliteration.trim().isNotEmpty ||
              step.translation.trim().isNotEmpty,
        )
        .toList(growable: false);
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

  static const Map<String, String> _namazStepImageByCode = {
    'takbir': 'assets/namaz/images/takbir.svg',
    'ruku': 'assets/namaz/images/ruku.svg',
    'qiyam': 'assets/namaz/images/stay.svg',
    'standing': 'assets/namaz/images/stay.svg',
    'straightening': 'assets/namaz/images/stay.svg',
    'qawmah': 'assets/namaz/images/stay.svg',
    'sujud': 'assets/namaz/images/sudjud.svg',
    'sajda': 'assets/namaz/images/sudjud.svg',
    'jalsa': 'assets/namaz/images/seat.svg',
    'sitting': 'assets/namaz/images/seat.svg',
    'qaada': 'assets/namaz/images/seat.svg',
    'tashahhud': 'assets/namaz/images/at-tahiyat.svg',
    'at_tahiyat': 'assets/namaz/images/at-tahiyat.svg',
    'taslim_left': 'assets/namaz/images/taslim-left.svg',
    'taslim_right': 'assets/namaz/images/taslim-right.svg',
  };

  String _stepImageAssetFor({
    required String stepCode,
    required String fallbackAsset,
  }) {
    final normalized = stepCode.trim().toLowerCase();
    if (normalized.isEmpty) return fallbackAsset;
    return _namazStepImageByCode[normalized] ?? fallbackAsset;
  }

  Widget _buildStepImage({
    required String stepImageAsset,
    required String fallbackStepImageAsset,
  }) {
    if (stepImageAsset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(stepImageAsset, height: 205.h);
    }
    return Image.asset(
      stepImageAsset,
      height: 205.h,
      errorBuilder: (context, error, stack) =>
          Image.asset(fallbackStepImageAsset, height: 205.h),
    );
  }

  Widget _buildTransitionPreview({
    required int rakaatIndex,
    required int stepIndex,
    required String prayerTitle,
  }) {
    final colors = context.colors;
    final totalRakaats = _rakaats.isEmpty ? 2 : _rakaats.length;
    final normalizedRakaatIndex = _rakaats.isEmpty
        ? 0
        : rakaatIndex.clamp(0, _rakaats.length - 1);
    final stepOrderIndexes = _stepOrderIndexesForRakaatIndex(
      normalizedRakaatIndex,
    );
    final clampedStepIndex = stepOrderIndexes.isEmpty
        ? 0
        : stepIndex.clamp(0, stepOrderIndexes.length - 1);
    final displayProgress = _displayStepProgressFor(
      rakaatIndex: normalizedRakaatIndex,
      stepIndex: clampedStepIndex,
    );
    final totalSteps = displayProgress.total;
    final stepIndexLabel = displayProgress.current;
    final rakaatIndexLabel = normalizedRakaatIndex + 1;
    final stepProgress = totalSteps == 0 ? 0.0 : (stepIndexLabel / totalSteps);
    final stepEntries = _stepEntriesFor(
      rakaatIndex: normalizedRakaatIndex,
      stepIndex: clampedStepIndex,
    );
    final recitationEntries = _recitationEntriesFor(
      rakaatIndex: normalizedRakaatIndex,
      stepIndex: clampedStepIndex,
    );
    final previewStep = stepEntries.firstOrNull;
    final stepTitle = (previewStep?.title ?? '').trim().isEmpty
        ? context.t('stage.defaultStepTitle')
        : previewStep!.title;
    final movementDescription = (previewStep?.movementDescription ?? '').trim();
    final fallbackStepImageAsset = _rakaats.isEmpty
        ? 'assets/icons/salat.png'
        : _rakaats[normalizedRakaatIndex].imageAsset;
    final currentStepCode = (previewStep?.stepCode ?? '');
    final currentStepImageAsset = _stepImageAssetFor(
      stepCode: currentStepCode,
      fallbackAsset: fallbackStepImageAsset,
    );
    final additionalSurahOptions = _rakaats.isEmpty
        ? const <RakaatSurahOption>[]
        : _rakaats[normalizedRakaatIndex].additionalSurahOptions;
    final hasAdditionalSurahSelector =
        additionalSurahOptions.isNotEmpty &&
        _isAdditionalSurahStep(previewStep);
    final selectedAdditionalSurahIndex = _selectedAdditionalSurahIndexForStep(
      additionalSurahOptions,
      previewStep,
    );
    final selectedPreviewAyahIndex = recitationEntries.isEmpty
        ? 0
        : _selectedAyahIndex.clamp(0, recitationEntries.length - 1);
    final previewEntryKey =
        'preview-r$normalizedRakaatIndex-s$clampedStepIndex-a$selectedPreviewAyahIndex';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 12.h),
        StageTopBar(
          onBack: () {},
          onStage: () {},
          stageButtonKey: _transitionStageButtonKey,
        ),
        SizedBox(height: 20.h),
        StageProgressBlock(
          title: context.t(
            'stage.prayerTitleWithRakaats',
            namedArgs: {'title': prayerTitle, 'count': '$totalRakaats'},
          ),
          rakaatIndex: rakaatIndexLabel,
          totalRakaats: totalRakaats,
          stepIndex: stepIndexLabel,
          totalSteps: totalSteps,
          progress: stepProgress.clamp(0.0, 1.0),
          animateProgress: false,
        ),
        SizedBox(height: 12.h),
        StageCard(
          child: Column(
            children: [
              Container(
                height: 260.h,
                decoration: BoxDecoration(
                  color: colors.soft,
                  borderRadius: BorderRadius.circular(AppRadii.inner.r),
                ),
                child: Center(
                  child: _buildStepImage(
                    stepImageAsset: currentStepImageAsset,
                    fallbackStepImageAsset: fallbackStepImageAsset,
                  ),
                ),
              ),
              SizedBox(height: 25.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    stepTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (movementDescription.isNotEmpty)
                    Text(
                      movementDescription,
                      style: TextStyle(
                        fontSize: 16.sp,
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
        SizedBox(height: 12.h),
        if (hasAdditionalSurahSelector) ...[
          StageSurahSelector(
            labels: additionalSurahOptions
                .map((option) => option.label)
                .toList(growable: false),
            selectedIndex: selectedAdditionalSurahIndex,
            onSelect: (_) {},
          ),
          SizedBox(height: 12.h),
        ],
        Column(
          children: [
            for (var i = 0; i < recitationEntries.length; i++) ...[
              KeyedSubtree(
                key: ValueKey('$previewEntryKey-$i'),
                child: StageAyahCard(
                  ayahIndex: i,
                  ayah: recitationEntries[i],
                  selected: i == selectedPreviewAyahIndex,
                  isPlaying: false,
                  progress: 0,
                  onTap: () {},
                  onPlayPause: () {},
                ),
              ),
              if (i != recitationEntries.length - 1) SizedBox(height: 16.h),
            ],
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: StageBottomButton(
                variant: StageBottomButtonVariant.secondary,
                label: context.t('common.back'),
                icon: 'assets/icons/arrow-left.svg',
                onTap: () {},
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 4,
              child: StageBottomButton(
                variant: StageBottomButtonVariant.primary,
                label: context.t('common.next'),
                icon: 'assets/icons/arrow-right.svg',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
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

  Future<void> _advanceAndPlayNextStep() async {
    if (_currentRecitationEntries.isEmpty) return;
    if (_clampedAyahIndex < _currentRecitationEntries.length - 1) {
      await _selectAyahInCurrentStep(
        _clampedAyahIndex + 1,
        playIfAutoplay: true,
      );
      return;
    }
    if (_clampedStepIndex < _currentStepOrderIndexes.length - 1) {
      await _animateStepTransitionTo(
        _clampedStepIndex + 1,
        direction: 1,
        playIfAutoplay: true,
      );
      return;
    }
    _autoplayEnabled = false;
    _playingStepKey = null;
  }

  Future<void> _nextStep() async {
    if (_currentStepOrderIndexes.isEmpty) return;
    if (_clampedStepIndex < _currentStepOrderIndexes.length - 1) {
      await _animateStepTransitionTo(
        _clampedStepIndex + 1,
        direction: 1,
        playIfAutoplay: false,
      );
      return;
    }
    if (_rakaats.isEmpty) return;
    final next = (_rakaatIndex + 1).clamp(0, _rakaats.length - 1);
    if (next == _rakaatIndex) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('stage.prayerCompleted'))),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      Navigator.of(context).maybePop();
      return;
    }
    await _animateRakaatTransitionTo(next, direction: 1, stepIndex: 0);
  }

  Future<void> _animateStepTransitionTo(
    int stepIndex, {
    required int direction,
    required bool playIfAutoplay,
  }) async {
    if (_pageTransitionController.isAnimating) return;
    if (_currentStepOrderIndexes.isEmpty) return;
    final nextStep = stepIndex.clamp(0, _currentStepOrderIndexes.length - 1);
    final resumeAutoplay = playIfAutoplay && _autoplayEnabled;

    _rakaatDirection = direction;
    _playingStepKey = null;
    _completedStepKey = null;
    await _audio.pause();

    _pendingRakaatIndex = _rakaatIndex;
    _pendingStepIndex = nextStep;
    _pendingJumpTop = false;
    _appliedPendingTransition = false;

    await _pageTransitionController.forward(from: 0);
    if (!mounted) return;
    if (!_appliedPendingTransition) {
      _applyPendingTransition(_rakaatIndex, nextStep);
    }
    _pendingRakaatIndex = null;
    _pendingStepIndex = null;
    _pendingJumpTop = false;
    _appliedPendingTransition = false;

    if (resumeAutoplay && (_selectedAyahStep?.hasAudio ?? false)) {
      await _playCurrent();
    }
  }

  Future<void> _animateRakaatTransitionTo(
    int index, {
    required int direction,
    required int stepIndex,
  }) async {
    if (_pageTransitionController.isAnimating) return;
    _autoplayEnabled = false;
    _rakaatDirection = direction;
    _playingStepKey = null;
    _completedStepKey = null;
    await _audio.pause();

    _pendingRakaatIndex = index;
    _pendingStepIndex = stepIndex;
    _pendingJumpTop = true;
    _appliedPendingTransition = false;

    await _pageTransitionController.forward(from: 0);
    if (!mounted) return;
    if (!_appliedPendingTransition) {
      _applyPendingTransition(index, stepIndex);
    }
    _pendingRakaatIndex = null;
    _pendingStepIndex = null;
    _pendingJumpTop = false;
    _appliedPendingTransition = false;
  }

  Future<void> _prevStep() async {
    if (_currentStepOrderIndexes.isEmpty) return;
    if (_clampedStepIndex > 0) {
      await _animateStepTransitionTo(
        _clampedStepIndex - 1,
        direction: -1,
        playIfAutoplay: false,
      );
      return;
    }
    if (_rakaats.isEmpty) return;
    final prev = (_rakaatIndex - 1).clamp(0, _rakaats.length - 1);
    if (prev == _rakaatIndex) return;
    final prevStepCount = _stepCountForRakaat(prev);
    final prevStepIndex = prevStepCount == 0 ? 0 : prevStepCount - 1;
    await _animateRakaatTransitionTo(
      prev,
      direction: -1,
      stepIndex: prevStepIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textScale = ThemeTextSizeStore.scale;
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
    final prayerTitle = widget.prayerTitle.trim().isEmpty
        ? context.t('stage.prayerDefaultTitle')
        : widget.prayerTitle;
    final stepTitle = (currentStep?.title ?? '').trim().isEmpty
        ? context.t('stage.defaultStepTitle')
        : currentStep!.title;
    final movementDescription = (currentStep?.movementDescription ?? '').trim();
    final floatingPlayerTitle = (_selectedAyahStep?.transliteration ?? '')
        .trim();
    final showFloatingPlayer =
        (_selectedAyahStep?.hasAudio ?? false) &&
        (_playingStepKey == _stepKey || _audio.isPlaying);
    final fallbackStepImageAsset =
        _currentRakaat?.imageAsset ?? 'assets/icons/salat.png';
    final currentStepCode = (currentStep?.stepCode ?? '');
    final currentStepImageAsset = _stepImageAssetFor(
      stepCode: currentStepCode,
      fallbackAsset: fallbackStepImageAsset,
    );
    final additionalSurahOptions = _additionalSurahOptions;
    final hasAdditionalSurahSelector =
        additionalSurahOptions.isNotEmpty &&
        _isAdditionalSurahStep(currentStep);
    final selectedAdditionalSurahIndex = _selectedAdditionalSurahIndex(
      additionalSurahOptions,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final currentStepEntries = _currentRecitationEntries;
    final selectedAyahCardKey = _stepKeys.putIfAbsent(
      _entryKey(_clampedAyahIndex),
      () => GlobalKey(),
    );

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.only(
                    bottom: 24.h + bottomInset,
                    top: 60.h,
                  ),
                  child: AnimatedBuilder(
                    animation: _pageTransitionController,
                    builder: (context, child) {
                      final targetRakaatIndex = _pendingRakaatIndex;
                      final targetStepIndex = _pendingStepIndex;
                      final isAnimating =
                          _pageTransitionController.isAnimating &&
                          targetRakaatIndex != null &&
                          targetStepIndex != null;
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final pageWidth = (screenWidth - 32.w).clamp(
                        0.0,
                        double.infinity,
                      );
                      final travelDistance = pageWidth + 32.w;
                      final progress = Curves.easeInOutBack.transform(
                        _pageTransitionController.value.clamp(0.0, 1.0),
                      );
                      final oldPageDx = isAnimating
                          ? -_rakaatDirection * travelDistance * progress
                          : 0.0;
                      final newPageDx =
                          oldPageDx + (_rakaatDirection * travelDistance);
                      return IgnorePointer(
                        ignoring: isAnimating,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Transform.translate(
                              offset: Offset(oldPageDx, 0),
                              child: child,
                            ),
                            if (isAnimating)
                              Transform.translate(
                                offset: Offset(newPageDx, 0),
                                child: _buildTransitionPreview(
                                  rakaatIndex: targetRakaatIndex,
                                  stepIndex: targetStepIndex,
                                  prayerTitle: prayerTitle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 12.h),
                        StageTopBar(
                          onBack: () => Navigator.of(context).maybePop(),
                          onStage: _showStageSheet,
                          stageButtonKey: _stageButtonKey,
                        ),
                        SizedBox(height: 20.h),
                        _animateAppear(
                          KeyedSubtree(
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
                                        stepImageAsset: currentStepImageAsset,
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
                                          fontSize: 16.sp,
                                          height: 1,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      if (movementDescription.isNotEmpty)
                                        Text(
                                          movementDescription,
                                          style: TextStyle(
                                            fontSize: 16.sp,
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
                                  KeyedSubtree(
                                    key: _stepKeys.putIfAbsent(
                                      _entryKey(i),
                                      () => GlobalKey(),
                                    ),
                                    child: StageAyahCard(
                                      ayahIndex: i,
                                      ayah: currentStepEntries[i],
                                      selected: i == _clampedAyahIndex,
                                      isPlaying:
                                          (_playingStepKey == _entryKey(i)) &&
                                          _audio.isPlaying,
                                      progress:
                                          (_playingStepKey == _entryKey(i))
                                          ? audioProgress.clamp(0.0, 1.0)
                                          : 0.0,
                                      onTap: () => _playStepAt(i),
                                      onPlayPause: () {
                                        if (i == _clampedAyahIndex) {
                                          _togglePlay();
                                        } else {
                                          _playStepAt(i);
                                        }
                                      },
                                    ),
                                  ),
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
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: StageBottomButton(
                                variant: StageBottomButtonVariant.secondary,
                                label: context.t('common.back'),
                                icon: 'assets/icons/arrow-left.svg',
                                onTap: _prevStep,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 4,
                              child: StageBottomButton(
                                variant: StageBottomButtonVariant.primary,
                                label: context.t('common.next'),
                                icon: 'assets/icons/arrow-right.svg',
                                onTap: _nextStep,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16.w,
                right: 16.w,
                top: 64.h,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _showPinned ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_showPinned,
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
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 8.h + bottomInset,
                child: IgnorePointer(
                  ignoring: !showFloatingPlayer,
                  child: AnimatedSlide(
                    offset: showFloatingPlayer
                        ? Offset.zero
                        : const Offset(0, 1.2),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: showFloatingPlayer ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _FloatingPlayer(
                        title: floatingPlayerTitle.isEmpty
                            ? stepTitle
                            : floatingPlayerTitle,
                        isPlaying: _audio.isPlaying,
                        onPlayPause: _togglePlay,
                      ),
                    ),
                  ),
                ),
              ),
              if (_showOnboarding)
                Positioned.fill(
                  child: StageOnboardingOverlay(
                    stageButtonKey: _stageButtonKey,
                    progressCardKey: _progressKey,
                    selectedAyahCardKey: selectedAyahCardKey,
                    onFinish: () => setState(() => _showOnboarding = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStageSheet() async {
    if (_rakaats.isEmpty) return;
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
                                onTap: () =>
                                    setModalState(() => selectedRakaat = i),
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
                            onTap: () => Navigator.of(context).pop(
                              _StageSectionSelection(selectedRakaat, index),
                            ),
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

    _autoplayEnabled = false;
    _playingStepKey = null;
    _completedStepKey = null;
    await _audio.pause();

    setState(() {
      _rakaatDirection = nextRakaat >= _rakaatIndex ? 1 : -1;
      _rakaatIndex = nextRakaat;
      _stepIndex = nextStep;
      _selectedAyahIndex = 0;
    });

    if (_selectedAyahStep?.hasAudio ?? false) {
      await _audio.setAyah(_stepToAyah(_selectedAyahStep!, _stepKey));
    }
    _scrollToCurrentAyah();
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

class _StageStepGroup {
  const _StageStepGroup({required this.title});

  final String title;
}

class _DisplayedStepProgress {
  const _DisplayedStepProgress({required this.current, required this.total});

  final int current;
  final int total;
}

class _FloatingPlayer extends StatelessWidget {
  const _FloatingPlayer({
    required this.title,
    required this.isPlaying,
    required this.onPlayPause,
  });

  final String title;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(AppRadii.pill.r),
            ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill.r),
            child: SizedBox(
              height: 78.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: colors.soft),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 84.w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(24),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: onPlayPause,
                        borderRadius: BorderRadius.circular(AppRadii.circle),
                        child: SizedBox(
                          width: 52.r,
                          height: 52.r,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: SvgPicture.asset(
                                isPlaying
                                    ? 'assets/icons/pause.svg'
                                    : 'assets/icons/play.svg',
                                key: ValueKey(isPlaying),
                                width: 24.r,
                                height: 24.r,
                                colorFilter: ColorFilter.mode(
                                  colors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
