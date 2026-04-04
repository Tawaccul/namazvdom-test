import '../domain/entities/app_madhhab.dart';
import '../domain/repositories/madhhab_repository.dart';

class MadhhabRepositoryMemory implements MadhhabRepository {
  MadhhabRepositoryMemory._();

  static final MadhhabRepositoryMemory instance = MadhhabRepositoryMemory._();

  static const _madhhabs = <AppMadhhab>[
    AppMadhhab(id: 'maliki', label: 'Маликитский'),
    AppMadhhab(id: 'hanafi', label: 'Ханафитский', recommended: true),
    AppMadhhab(id: 'shafii', label: 'Шафитский'),
    AppMadhhab(id: 'hanbali', label: 'Ханбалитский'),
  ];

  AppMadhhab _selected = _madhhabs[1];

  @override
  List<AppMadhhab> getAvailableMadhhabs() => _madhhabs;

  @override
  AppMadhhab getSelectedMadhhab() => _selected;

  @override
  void setSelectedMadhhab(AppMadhhab madhhab) {
    _selected = madhhab;
  }
}

