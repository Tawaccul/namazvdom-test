import 'package:flutter/foundation.dart';

import '../domain/entities/app_language.dart';
import '../domain/usecases/get_available_languages.dart';
import '../domain/usecases/get_selected_language.dart';
import '../domain/usecases/set_selected_language.dart';

class LanguageController extends ChangeNotifier {
  LanguageController({
    required GetAvailableLanguages getAvailableLanguages,
    required GetSelectedLanguage getSelectedLanguage,
    required SetSelectedLanguage setSelectedLanguage,
  }) : _getAvailableLanguages = getAvailableLanguages,
       _getSelectedLanguage = getSelectedLanguage,
       _setSelectedLanguage = setSelectedLanguage {
    languages = _getAvailableLanguages();
    selected = _getSelectedLanguage();
  }

  final GetAvailableLanguages _getAvailableLanguages;
  final GetSelectedLanguage _getSelectedLanguage;
  final SetSelectedLanguage _setSelectedLanguage;

  late final List<AppLanguage> languages;
  late AppLanguage selected;

  void select(AppLanguage language) {
    if (language.id == selected.id) return;
    _setSelectedLanguage(language);
    selected = language;
    notifyListeners();
  }
}
