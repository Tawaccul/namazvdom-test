import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLauncherIconController {
  static const MethodChannel _channel = MethodChannel('prayday/app_icon');

  Future<void> setDarkIconEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setDarkIconEnabled', {
        'enabled': enabled,
      });
    } on PlatformException catch (e) {
      debugPrint('App icon change failed: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('App icon change failed: $e');
    }
  }
}
