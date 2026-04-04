import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class GetAvailableLanguages {
  const GetAvailableLanguages(this._repository);

  final LanguageRepository _repository;

  List<AppLanguage> call() => _repository.getAvailableLanguages();
}
