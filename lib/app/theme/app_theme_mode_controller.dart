import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeModeController extends ChangeNotifier {
  static const _themeModeKey = 'app.theme.mode';
  ThemeMode _mode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get mode => _mode;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = _themeModeFromId(prefs.getString(_themeModeKey));
    } catch (_) {
      _mode = ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _persistMode();
  }

  ThemeMode _themeModeFromId(String? id) {
    return switch (id) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _themeModeId(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  Future<void> _persistMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeId(_mode));
    } catch (_) {}
  }
}
