import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/quran/model/quran_ayah.dart';
import 'ayah_audio.dart';

class AyahAudioController extends ChangeNotifier implements AyahAudio {
  AyahAudioController() {
    // Lazy init: just_audio is not available on every platform, and plugins
    // aren't registered after hot reload when adding a new plugin.
  }

  AudioPlayer? _player;
  Object? _initError;

  QuranAyah? _current;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  QuranAyah? get current => _current;

  @override
  bool get isPlaying => _player?.playing ?? false;

  Duration get position => _player?.position ?? Duration.zero;
  Duration get duration => _player?.duration ?? Duration.zero;

  @override
  double get progress {
    if (_player == null) return 0;
    final d = duration.inMilliseconds;
    if (d <= 0) return 0;
    return (position.inMilliseconds / d).clamp(0.0, 1.0);
  }

  @override
  bool get isCompleted =>
      _player?.playerState.processingState == ProcessingState.completed;

  bool get isAvailable => _initError == null;

  Object? get initError => _initError;

  bool _ensurePlayer() {
    if (_initError != null) return false;
    if (_player != null) return true;
    try {
      _player = AudioPlayer();
      _posSub = _player!.positionStream.listen((_) => _emit());
      _durSub = _player!.durationStream.listen((_) => _emit());
      _stateSub = _player!.playerStateStream.listen((_) => _emit());
      return true;
    } on MissingPluginException catch (e) {
      _initError = e;
      return false;
    } on PlatformException catch (e) {
      _initError = e;
      return false;
    } catch (e) {
      _initError = e;
      return false;
    }
  }

  @override
  Future<void> setAyah(QuranAyah ayah) async {
    if (!_ensurePlayer()) {
      throw UnsupportedError(
        'Audio player plugin is not available on this platform/build.',
      );
    }
    if (_current?.surahId == ayah.surahId &&
        _current?.ayahId == ayah.ayahId &&
        _current?.audioUrl == ayah.audioUrl) {
      return;
    }
    _current = ayah;
    await _player!.stop();
    if (ayah.audioUrl.startsWith('assets/')) {
      await _player!.setAsset(ayah.audioUrl);
    } else {
      await _player!.setUrl(ayah.audioUrl);
    }
    notifyListeners();
  }

  @override
  Future<void> toggle() async {
    if (!_ensurePlayer()) {
      throw UnsupportedError(
        'Audio player plugin is not available on this platform/build.',
      );
    }
    if (_player!.playing) {
      await pause();
    } else {
      await play();
    }
    notifyListeners();
  }

  @override
  Future<void> play() async {
    if (!_ensurePlayer()) {
      throw UnsupportedError(
        'Audio player plugin is not available on this platform/build.',
      );
    }
    final state = _player!.playerState;
    final isCompleted = state.processingState == ProcessingState.completed;
    final isAtEnd =
        duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 50);
    if (isCompleted || isAtEnd) {
      await _player!.seek(Duration.zero);
    }
    await _player!.play();
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    if (!_ensurePlayer()) {
      throw UnsupportedError(
        'Audio player plugin is not available on this platform/build.',
      );
    }
    await _player!.pause();
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    if (_player == null) return;
    await _player!.stop();
    notifyListeners();
  }

  void _emit() {
    final now = DateTime.now();
    if (now.difference(_lastEmit).inMilliseconds < 100) return;
    _lastEmit = now;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _stateSub?.cancel();
    if (_player != null) {
      try {
        await _player!.dispose();
      } catch (_) {
        // Ignore dispose errors if plugin is missing.
      }
    }
    super.dispose();
  }
}
