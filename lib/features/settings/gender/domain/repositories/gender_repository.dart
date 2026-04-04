import '../entities/app_gender.dart';

abstract class GenderRepository {
  List<AppGender> getAvailableGenders();
  AppGender getSelectedGender();
  void setSelectedGender(AppGender gender);
}

