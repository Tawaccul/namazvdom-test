import '../entities/prayer_meta.dart';
import '../entities/prayer_request_context.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerMeta {
  GetPrayerMeta(this._repository);

  final PrayerRepository _repository;

  Future<PrayerMeta> call({PrayerRequestContext? context}) =>
      _repository.getRemoteMeta(context: context);
}
