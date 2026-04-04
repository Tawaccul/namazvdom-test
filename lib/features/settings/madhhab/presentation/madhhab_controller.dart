import 'package:flutter/foundation.dart';

import '../domain/entities/app_madhhab.dart';
import '../domain/usecases/get_available_madhhabs.dart';
import '../domain/usecases/get_selected_madhhab.dart';
import '../domain/usecases/set_selected_madhhab.dart';

class MadhhabController extends ChangeNotifier {
  MadhhabController({
    required GetAvailableMadhhabs getAvailableMadhhabs,
    required GetSelectedMadhhab getSelectedMadhhab,
    required SetSelectedMadhhab setSelectedMadhhab,
  }) : _getAvailableMadhhabs = getAvailableMadhhabs,
       _getSelectedMadhhab = getSelectedMadhhab,
       _setSelectedMadhhab = setSelectedMadhhab {
    _madhhabs = _getAvailableMadhhabs();
    _selected = _getSelectedMadhhab();
  }

  final GetAvailableMadhhabs _getAvailableMadhhabs;
  final GetSelectedMadhhab _getSelectedMadhhab;
  final SetSelectedMadhhab _setSelectedMadhhab;

  late final List<AppMadhhab> _madhhabs;
  late AppMadhhab _selected;

  List<AppMadhhab> get madhhabs => _madhhabs;
  AppMadhhab get selected => _selected;

  void select(AppMadhhab madhhab) {
    if (madhhab.id == _selected.id) return;
    _setSelectedMadhhab(madhhab);
    _selected = madhhab;
    notifyListeners();
  }
}

