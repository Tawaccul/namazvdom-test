import '../entities/app_madhhab.dart';
import '../repositories/madhhab_repository.dart';

class GetSelectedMadhhab {
  GetSelectedMadhhab(this._repository);

  final MadhhabRepository _repository;

  AppMadhhab call() => _repository.getSelectedMadhhab();
}

