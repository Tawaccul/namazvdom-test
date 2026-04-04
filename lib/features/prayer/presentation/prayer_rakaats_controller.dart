import 'package:flutter/foundation.dart';

import '../domain/entities/prayer_rakaat.dart';
import '../domain/entities/prayer_request_context.dart';
import '../domain/usecases/get_prayer_rakaats.dart';

sealed class PrayerRakaatsState {
  const PrayerRakaatsState();
}

class PrayerRakaatsInitial extends PrayerRakaatsState {
  const PrayerRakaatsInitial();
}

class PrayerRakaatsLoading extends PrayerRakaatsState {
  const PrayerRakaatsLoading();
}

class PrayerRakaatsLoaded extends PrayerRakaatsState {
  const PrayerRakaatsLoaded(this.rakaats);

  final List<PrayerRakaat> rakaats;
}

class PrayerRakaatsError extends PrayerRakaatsState {
  const PrayerRakaatsError(this.message);

  final String message;
}

class PrayerRakaatsController extends ChangeNotifier {
  PrayerRakaatsController({required GetPrayerRakaats getPrayerRakaats})
    : _getPrayerRakaats = getPrayerRakaats;

  final GetPrayerRakaats _getPrayerRakaats;

  PrayerRakaatsState _state = const PrayerRakaatsInitial();
  PrayerRakaatsState get state => _state;

  Future<void> load({required PrayerRequestContext baseContext}) async {
    _state = const PrayerRakaatsLoading();
    notifyListeners();
    try {
      final rakaats = await _getPrayerRakaats(baseContext: baseContext);
      _state = PrayerRakaatsLoaded(rakaats);
      notifyListeners();
    } catch (e) {
      _state = PrayerRakaatsError(e.toString());
      notifyListeners();
    }
  }
}
