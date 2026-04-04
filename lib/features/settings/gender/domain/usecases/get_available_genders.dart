import '../entities/app_gender.dart';
import '../repositories/gender_repository.dart';

class GetAvailableGenders {
  GetAvailableGenders(this._repository);

  final GenderRepository _repository;

  List<AppGender> call() => _repository.getAvailableGenders();
}

