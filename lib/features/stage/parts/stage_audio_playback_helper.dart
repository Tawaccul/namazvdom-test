import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/audio/ayah_audio.dart';
import '../../quran/model/quran_ayah.dart';
import '../models/rakaat_models.dart';

class StageAudioPlaybackHelper {
  static QuranAyah stepToAyah({
    required RakaatStep step,
    required String id,
    required String Function(String entryKey) audioUrlForEntry,
  }) {
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
      audioUrl: audioUrlForEntry(id),
    );
  }

  static Future<bool> waitForPlaybackCompletion({
    required AyahAudio audio,
    required int sessionId,
    required String stepKey,
    required bool Function(int sessionId) isAutoplaySessionActive,
    required String? Function() getPlayingStepKey,
    required void Function(String? value) setStartedPlaybackStepKey,
    required String? Function() getStartedPlaybackStepKey,
  }) {
    final completer = Completer<bool>();
    var lastWasPlaying = audio.isPlaying;

    void finish(bool value, VoidCallback listener) {
      if (completer.isCompleted) return;
      audio.removeListener(listener);
      completer.complete(value);
    }

    late final VoidCallback listener;
    listener = () {
      if (!isAutoplaySessionActive(sessionId) ||
          getPlayingStepKey() != stepKey) {
        finish(false, listener);
        return;
      }
      final isPlaying = audio.isPlaying;
      if (getPlayingStepKey() == stepKey && isPlaying) {
        setStartedPlaybackStepKey(stepKey);
      }
      final reachedEnd = audio.progress >= 0.98;
      final completedByProgress = !isPlaying && lastWasPlaying && reachedEnd;
      final completed =
          getStartedPlaybackStepKey() == stepKey &&
          (audio.isCompleted || completedByProgress);
      lastWasPlaying = isPlaying;
      if (completed) {
        finish(true, listener);
      }
    };

    audio.addListener(listener);
    listener();
    return completer.future;
  }

  static Future<void> startPageAutoplayFrom({
    required int ayahIndex,
    required List<RakaatStep> currentRecitationEntries,
    required void Function({bool disableAutoplay}) cancelAutoplaySequence,
    required void Function(bool value) setAutoplayEnabled,
    required int Function() getAutoplaySessionId,
    required bool Function(int sessionId) isAutoplaySessionActive,
    required Future<void> Function(int ayahIndex, {bool playIfAutoplay})
    selectAyahInCurrentStep,
    required String Function() getStepKey,
    required Future<void> Function() playCurrent,
    required Future<bool> Function(int sessionId, String stepKey)
    waitForPlaybackCompletion,
    required Future<void> Function() dismissFloatingPlayer,
    required void Function(String message) setError,
    required bool mounted,
  }) async {
    if (currentRecitationEntries.isEmpty) return;
    cancelAutoplaySequence();
    setAutoplayEnabled(true);
    final sessionId = getAutoplaySessionId();
    final startIndex = ayahIndex.clamp(0, currentRecitationEntries.length - 1);

    try {
      for (var i = startIndex; i < currentRecitationEntries.length; i++) {
        if (!isAutoplaySessionActive(sessionId)) return;
        await selectAyahInCurrentStep(i, playIfAutoplay: false);
        if (!isAutoplaySessionActive(sessionId)) return;
        final currentStepKey = getStepKey();
        await playCurrent();
        final completed = await waitForPlaybackCompletion(
          sessionId,
          currentStepKey,
        );
        if (!completed) return;
        if (i < currentRecitationEntries.length - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
      if (!isAutoplaySessionActive(sessionId)) return;
      await dismissFloatingPlayer();
    } catch (e) {
      if (!mounted) return;
      setError(e.toString());
    }
  }

  static Future<void> playCurrent({
    required AyahAudio audio,
    required RakaatStep? selectedAyahStep,
    required bool mounted,
    required String stepKey,
    required void Function(String? value) setPlayingStepKey,
    required void Function(String? value) setStartedPlaybackStepKey,
    required VoidCallback notifyUi,
  }) async {
    final step = selectedAyahStep;
    if (step == null || !step.hasAudio) return;
    setPlayingStepKey(stepKey);
    setStartedPlaybackStepKey(null);
    if (mounted) {
      notifyUi();
    }
    await audio.play();
  }

  static Future<void> dismissFloatingPlayer({
    required AyahAudio audio,
    required bool mounted,
    required void Function({bool disableAutoplay}) cancelAutoplaySequence,
    required void Function(String? value) setPlayingStepKey,
    required void Function(String? value) setStartedPlaybackStepKey,
    required VoidCallback notifyUi,
  }) async {
    cancelAutoplaySequence(disableAutoplay: true);
    setPlayingStepKey(null);
    setStartedPlaybackStepKey(null);
    if (mounted) {
      notifyUi();
    }
    await audio.pause();
  }

  static Future<void> selectAyahInCurrentStep({
    required int ayahIndex,
    required bool playIfAutoplay,
    required List<RakaatStep> currentRecitationEntries,
    required void Function(int next) setSelectedAyahIndex,
    required RakaatStep? Function() getSelectedAyahStep,
    required String Function() getStepKey,
    required bool Function() isAutoplayEnabled,
    required Future<void> Function(QuranAyah ayah) setAyah,
    required QuranAyah Function(RakaatStep step, String id) stepToAyah,
    required void Function(String? value) setPlayingStepKey,
    required void Function(String? value) setStartedPlaybackStepKey,
    required Future<void> Function() playCurrent,
  }) async {
    if (currentRecitationEntries.isEmpty) return;
    final next = ayahIndex.clamp(0, currentRecitationEntries.length - 1);
    setSelectedAyahIndex(next);
    final step = getSelectedAyahStep();
    if (step == null) return;
    if (step.hasAudio) {
      await setAyah(stepToAyah(step, getStepKey()));
    }
    setPlayingStepKey(null);
    setStartedPlaybackStepKey(null);
    if (playIfAutoplay && isAutoplayEnabled() && step.hasAudio) {
      await playCurrent();
    }
  }

  static Future<void> togglePlay({
    required AyahAudio audio,
    required RakaatStep? selectedAyahStep,
    required String stepKey,
    required String? playingStepKey,
    required bool mounted,
    required List<RakaatStep> currentRecitationEntries,
    required Future<void> Function() startPageAutoplayFromCurrentAyah,
    required Future<void> Function(QuranAyah ayah) setAyah,
    required QuranAyah Function(RakaatStep step, String id) stepToAyah,
    required Future<void> Function() playCurrent,
    required VoidCallback notifyUi,
    required void Function(String message) setError,
  }) async {
    final step = selectedAyahStep;
    if (step == null || !step.hasAudio) return;
    try {
      if (audio.isPlaying) {
        await audio.pause();
        if (mounted) {
          notifyUi();
        }
        return;
      }

      if (playingStepKey == stepKey) {
        await audio.play();
        if (mounted) {
          notifyUi();
        }
        return;
      }

      if (currentRecitationEntries.isNotEmpty) {
        await startPageAutoplayFromCurrentAyah();
      } else {
        await setAyah(stepToAyah(step, stepKey));
        await playCurrent();
      }
    } catch (e) {
      setError(e.toString());
    }
  }
}
