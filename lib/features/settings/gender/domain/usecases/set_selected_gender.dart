import '../entities/app_gender.dart';
import '../repositories/gender_repository.dart';

class SetSelectedGender {
  SetSelectedGender(this._repository);

  final GenderRepository _repository;

  void call(AppGender gender) => _repository.setSelectedGender(gender);
}

