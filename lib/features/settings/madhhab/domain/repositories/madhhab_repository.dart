import '../entities/app_madhhab.dart';

abstract class MadhhabRepository {
  List<AppMadhhab> getAvailableMadhhabs();
  AppMadhhab getSelectedMadhhab();
  void setSelectedMadhhab(AppMadhhab madhhab);
}

