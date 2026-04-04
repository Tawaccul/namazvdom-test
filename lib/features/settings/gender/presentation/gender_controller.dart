import 'package:flutter/foundation.dart';

import '../domain/entities/app_gender.dart';
import '../domain/usecases/get_available_genders.dart';
import '../domain/usecases/get_selected_gender.dart';
import '../domain/usecases/set_selected_gender.dart';

class GenderController extends ChangeNotifier {
  GenderController({
    required GetAvailableGenders getAvailableGenders,
    required GetSelectedGender getSelectedGender,
    required SetSelectedGender setSelectedGender,
  }) : _getAvailableGenders = getAvailableGenders,
       _getSelectedGender = getSelectedGender,
       _setSelectedGender = setSelectedGender {
    _genders = _getAvailableGenders();
    _selected = _getSelectedGender();
  }

  final GetAvailableGenders _getAvailableGenders;
  final GetSelectedGender _getSelectedGender;
  final SetSelectedGender _setSelectedGender;

  late final List<AppGender> _genders;
  late AppGender _selected;

  List<AppGender> get genders => _genders;
  AppGender get selected => _selected;

  void select(AppGender gender) {
    if (gender.id == _selected.id) return;
    _setSelectedGender(gender);
    _selected = gender;
    notifyListeners();
  }
}

