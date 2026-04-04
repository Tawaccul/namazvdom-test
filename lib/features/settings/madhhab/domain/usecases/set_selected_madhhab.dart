import '../entities/app_madhhab.dart';
import '../repositories/madhhab_repository.dart';

class SetSelectedMadhhab {
  SetSelectedMadhhab(this._repository);

  final MadhhabRepository _repository;

  void call(AppMadhhab madhhab) => _repository.setSelectedMadhhab(madhhab);
}

