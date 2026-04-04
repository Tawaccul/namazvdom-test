import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/key_value_store.dart';
import '../../core/storage/memory_key_value_store.dart';
import '../../core/storage/shared_preferences_key_value_store.dart';
import '../../core/network/dio_factory.dart';
import '../../features/prayer/data/datasources/prayer_cache_data_source.dart';
import '../../features/prayer/data/datasources/prayer_remote_data_source.dart';
import '../../features/prayer/data/meta_api.dart';
import '../../features/prayer/data/prayer_api.dart';
import '../../features/prayer/data/prayer_repository_impl.dart';
import '../../features/prayer/data/surah_api.dart';
import '../../features/prayer/domain/repositories/prayer_repository.dart';

abstract class AppDi {
  static Future<PrayerRepository> createPrayerRepository() async {
    final store = await _createKeyValueStore();
    final dio = DioFactory.create();
    final prayerApi = PrayerApi(dio);
    final metaApi = MetaApi(dio);
    final surahApi = SurahApi(dio);
    final remote = PrayerRemoteDataSource(prayerApi, metaApi, surahApi);
    final cache = PrayerCacheDataSource(store);
    return PrayerRepositoryImpl(remote: remote, cache: cache);
  }

  static Future<KeyValueStore> _createKeyValueStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SharedPreferencesKeyValueStore(prefs);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'SharedPreferences unavailable, using in-memory cache. Error: $e',
        );
      }
      return MemoryKeyValueStore();
    }
  }
}
