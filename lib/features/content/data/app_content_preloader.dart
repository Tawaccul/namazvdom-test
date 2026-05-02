import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../ablution/data/ablution_content_cache.dart';
import '../../stage/stage_prayer_loader.dart';

class AppContentPreloader {
  const AppContentPreloader._();

  static const Duration _taskTimeout = Duration(seconds: 12);

  static const List<String> _prayerCodes = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static Future<void> preload(BuildContext context) async {
    await Future.wait([
      _preloadAblution(),
      ..._prayerCodes.map((code) => _preloadPrayer(context, code)),
    ]);
  }

  static Future<void> _preloadAblution() async {
    try {
      await AblutionContentCache.syncFromServer().timeout(_taskTimeout);
    } catch (_) {
      // Bundled ablution content remains available without a successful sync.
    }
  }

  static Future<void> _preloadPrayer(BuildContext context, String code) async {
    try {
      await StagePrayerLoader.load(
        context,
        prayerCode: code,
      ).timeout(_taskTimeout);
    } catch (_) {
      // StagePrayerLoader already falls back to bundled assets when possible.
      // Startup preload should not prevent navigation if a single prayer fails.
    }
  }
}
