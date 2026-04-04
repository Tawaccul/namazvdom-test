import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class SetSelectedLanguage {
  const SetSelectedLanguage(this._repository);

  final LanguageRepository _repository;

  void call(AppLanguage language) => _repository.setSelectedLanguage(language);
}
