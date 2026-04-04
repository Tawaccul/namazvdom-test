import '../entities/prayer_rakaat.dart';
import '../entities/prayer_request_context.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerRakaats {
  GetPrayerRakaats(this._repository);

  final PrayerRepository _repository;

  Future<List<PrayerRakaat>> call({
    required PrayerRequestContext baseContext,
  }) async {
    final first = await _repository.getRakaat(
      context: baseContext.copyWith(rakah: 1),
    );

    final total = first.context.totalRakahCount.clamp(1, 20);
    if (total == 1) return [first];

    final futures = <Future<PrayerRakaat>>[];
    for (var rakah = 2; rakah <= total; rakah++) {
      futures.add(
        _repository.getRakaat(context: baseContext.copyWith(rakah: rakah)),
      );
    }
    final rest = await Future.wait(futures);
    final all = <PrayerRakaat>[first, ...rest]
      ..sort((a, b) => a.context.rakah.compareTo(b.context.rakah));
    return all;
  }
}
