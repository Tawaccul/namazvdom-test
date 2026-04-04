import '../entities/prayer_rakaat.dart';
import '../entities/prayer_request_context.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerRakaat {
  GetPrayerRakaat(this._repository);

  final PrayerRepository _repository;

  Future<PrayerRakaat> call({required PrayerRequestContext context}) {
    return _repository.getRakaat(context: context);
  }
}
