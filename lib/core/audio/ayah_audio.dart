import 'package:flutter/foundation.dart';

import '../../features/quran/model/quran_ayah.dart';

abstract class AyahAudio implements Listenable {
  QuranAyah? get current;
  bool get isPlaying;
  double get progress;
  bool get isCompleted;

  Future<void> setAyah(QuranAyah ayah);
  Future<void> play();
  Future<void> pause();
  Future<void> toggle();
  Future<void> stop();

  Future<void> dispose();
}
