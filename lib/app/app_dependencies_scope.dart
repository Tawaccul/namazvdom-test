import 'package:flutter/material.dart';

import '../features/prayer/domain/repositories/prayer_repository.dart';

class AppDependenciesScope extends InheritedWidget {
  const AppDependenciesScope({
    super.key,
    required this.prayerRepository,
    required super.child,
  });

  final PrayerRepository prayerRepository;

  static PrayerRepository prayerRepositoryOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    final repository = scope?.prayerRepository;
    if (repository == null) {
      throw StateError('AppDependenciesScope not found in widget tree.');
    }
    return repository;
  }

  @override
  bool updateShouldNotify(covariant AppDependenciesScope oldWidget) {
    return false;
  }
}
