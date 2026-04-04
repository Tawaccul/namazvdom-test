import 'dart:ui';

import '../domain/entities/app_language.dart';
import '../domain/repositories/language_repository.dart';

class LanguageRepositoryMemory implements LanguageRepository {
  LanguageRepositoryMemory._();

  static final LanguageRepositoryMemory instance = LanguageRepositoryMemory._();

  static const _languages = <AppLanguage>[
    AppLanguage(id: 'ru', label: 'Русский'),
    AppLanguage(id: 'en', label: 'English'),
  ];

  AppLanguage _selected = _languages.first;

  @override
  List<AppLanguage> getAvailableLanguages() => _languages;

  @override
  AppLanguage getSelectedLanguage() => _selected;

  @override
  void setSelectedLanguage(AppLanguage language) {
    _selected = language;
  }

  void syncWithLocale(Locale locale) {
    final normalizedCode = locale.languageCode.trim().toLowerCase();
    final fromSupported = _languages.firstWhere(
      (item) => item.id == normalizedCode,
      orElse: () => _languages.first,
    );
    _selected = fromSupported;
  }
}
