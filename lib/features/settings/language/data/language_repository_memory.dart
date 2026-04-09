import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_language.dart';
import '../domain/repositories/language_repository.dart';

class LanguageRepositoryMemory implements LanguageRepository {
  LanguageRepositoryMemory._();

  static final LanguageRepositoryMemory instance = LanguageRepositoryMemory._();
  static const _prefsKey = 'settings.language';

  static const _languages = <AppLanguage>[
    AppLanguage(id: 'ru', label: 'Русский'),
    AppLanguage(id: 'en', label: 'English'),
  ];

  AppLanguage _selected = _languages.first;
  bool _isInitialized = false;
  bool _hasPersistedSelection = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistedId = prefs.getString(_prefsKey)?.trim().toLowerCase() ?? '';
      if (persistedId.isNotEmpty) {
        _selected = _languages.firstWhere(
          (item) => item.id == persistedId,
          orElse: () => _languageForLocale(PlatformDispatcher.instance.locale),
        );
        _hasPersistedSelection = true;
        return;
      }
    } catch (_) {}
    _selected = _languageForLocale(PlatformDispatcher.instance.locale);
  }

  @override
  List<AppLanguage> getAvailableLanguages() => _languages;

  @override
  AppLanguage getSelectedLanguage() => _selected;

  @override
  void setSelectedLanguage(AppLanguage language) {
    _selected = _languages.firstWhere(
      (item) => item.id == language.id,
      orElse: () => _languages.first,
    );
    _hasPersistedSelection = true;
    _persistSelected();
  }

  void syncWithLocale(Locale locale) {
    if (_hasPersistedSelection) return;
    final normalizedCode = locale.languageCode.trim().toLowerCase();
    final fromSupported = _languages.firstWhere(
      (item) => item.id == normalizedCode,
      orElse: () => _languages.first,
    );
    _selected = fromSupported;
  }

  Locale get selectedLocale => Locale(_selected.id);

  AppLanguage _languageForLocale(Locale locale) {
    final normalizedCode = locale.languageCode.trim().toLowerCase();
    return _languages.firstWhere(
      (item) => item.id == normalizedCode,
      orElse: () => _languages.first,
    );
  }

  Future<void> _persistSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _selected.id);
    } catch (_) {}
  }
}
