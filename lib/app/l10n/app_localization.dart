import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const appSupportedLocales = <Locale>[Locale('ru'), Locale('en')];
const appFallbackLocale = Locale('ru');
const appTranslationsPath = 'assets/translations';

extension AppLocalizationX on BuildContext {
  String t(String key, {List<String>? args, Map<String, String>? namedArgs}) {
    return key.tr(args: args, namedArgs: namedArgs);
  }
}

String localizedLanguageLabel(BuildContext context, String languageId) {
  return switch (languageId) {
    'ru' => context.t('language.russian'),
    'en' => context.t('language.english'),
    _ => languageId,
  };
}

String localizedGenderLabel(BuildContext context, String genderId) {
  return switch (genderId) {
    'male' => context.t('gender.male'),
    'female' => context.t('gender.female'),
    _ => genderId,
  };
}

String localizedMadhhabLabel(BuildContext context, String madhhabId) {
  return switch (madhhabId) {
    'hanafi' => context.t('madhhab.names.hanafi'),
    'shafii' => context.t('madhhab.names.shafii'),
    'maliki' => context.t('madhhab.names.maliki'),
    'hanbali' => context.t('madhhab.names.hanbali'),
    _ => madhhabId,
  };
}

String localizedPrayerLabel(
  BuildContext context,
  String prayerCode, {
  String? fallbackTitle,
}) {
  final normalized = switch (prayerCode.trim().toLowerCase()) {
    'zuhr' => 'dhuhr',
    'magrib' => 'maghrib',
    final value => value,
  };
  final key = switch (normalized) {
    'fajr' => 'home.prayers.fajr.title',
    'dhuhr' => 'home.prayers.dhuhr.title',
    'asr' => 'home.prayers.asr.title',
    'maghrib' => 'home.prayers.maghrib.title',
    'isha' => 'home.prayers.isha.title',
    _ => null,
  };
  if (key == null) {
    final fallback = (fallbackTitle ?? '').trim();
    return fallback.isEmpty ? prayerCode : fallback;
  }
  final localized = context.t(key);
  if (localized == key) {
    final fallback = (fallbackTitle ?? '').trim();
    return fallback.isEmpty ? prayerCode : fallback;
  }
  return localized;
}
