import 'package:flutter/material.dart';

import 'theme/app_theme_mode_controller.dart';

class AppScope extends InheritedNotifier<AppThemeModeController> {
  const AppScope({
    super.key,
    required AppThemeModeController themeController,
    required super.child,
  }) : super(notifier: themeController);

  static AppThemeModeController themeControllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    final controller = scope?.notifier;
    if (controller == null) {
      throw StateError('AppScope not found in widget tree.');
    }
    return controller;
  }
}
