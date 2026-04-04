import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_gender.dart';
import '../domain/repositories/gender_repository.dart';

class GenderRepositoryMemory implements GenderRepository {
  GenderRepositoryMemory._();

  static final GenderRepositoryMemory instance = GenderRepositoryMemory._();
  static const _prefsKey = 'settings.gender';

  static const _genders = <AppGender>[
    AppGender(id: 'male', label: 'Male'),
    AppGender(id: 'female', label: 'Female'),
  ];

  AppGender _selected = _genders.first;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistedId =
          prefs.getString(_prefsKey)?.trim().toLowerCase() ?? '';
      if (persistedId.isEmpty) return;
      final persisted = _genders.firstWhere(
        (item) => item.id == persistedId,
        orElse: () => _genders.first,
      );
      _selected = persisted;
    } catch (_) {}
  }

  @override
  List<AppGender> getAvailableGenders() => _genders;

  @override
  AppGender getSelectedGender() => _selected;

  @override
  void setSelectedGender(AppGender gender) {
    _selected = _genders.firstWhere(
      (item) => item.id == gender.id,
      orElse: () => _genders.first,
    );
    unawaited(_persistSelected());
  }

  Future<void> _persistSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _selected.id);
    } catch (_) {}
  }
}
