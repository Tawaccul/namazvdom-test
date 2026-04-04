import '../entities/app_madhhab.dart';
import '../repositories/madhhab_repository.dart';

class GetAvailableMadhhabs {
  GetAvailableMadhhabs(this._repository);

  final MadhhabRepository _repository;

  List<AppMadhhab> call() => _repository.getAvailableMadhhabs();
}

