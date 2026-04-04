import '../entities/app_gender.dart';
import '../repositories/gender_repository.dart';

class GetSelectedGender {
  GetSelectedGender(this._repository);

  final GenderRepository _repository;

  AppGender call() => _repository.getSelectedGender();
}

