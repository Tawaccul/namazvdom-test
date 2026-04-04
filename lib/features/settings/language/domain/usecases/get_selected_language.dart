import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class GetSelectedLanguage {
  const GetSelectedLanguage(this._repository);

  final LanguageRepository _repository;

  AppLanguage call() => _repository.getSelectedLanguage();
}
