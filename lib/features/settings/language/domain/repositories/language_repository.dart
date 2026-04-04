import '../entities/app_language.dart';

abstract interface class LanguageRepository {
  List<AppLanguage> getAvailableLanguages();
  AppLanguage getSelectedLanguage();
  void setSelectedLanguage(AppLanguage language);
}
