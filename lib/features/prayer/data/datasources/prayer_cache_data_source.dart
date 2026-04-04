import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../models/prayer_meta_model.dart';
import '../models/prayer_rakaat_response_model.dart';
import '../models/prayer_surah_model.dart';

class PrayerCacheDataSource {
  PrayerCacheDataSource(this._store);

  final KeyValueStore _store;

  static const _metaPrefix = 'prayer_cache:meta:';
  static const _indexPrefix = 'prayer_cache:index:';
  static const _prayerPrefix = 'prayer_cache:prayer:';
  static const _surahPrefix = 'prayer_cache:surah:';
  static const _scopesKey = 'prayer_cache:scopes';
  static const _surahIndexKey = 'prayer_cache:surah_index';

  Future<List<String>> readScopes() async {
    return _store.getStringList(_scopesKey) ?? const <String>[];
  }

  Future<void> _rememberScope(String scopeKey) async {
    final existing = _store.getStringList(_scopesKey) ?? <String>[];
    if (existing.contains(scopeKey)) return;
    await _store.setStringList(_scopesKey, [...existing, scopeKey]);
  }

  Future<PrayerMetaModel?> readMeta({required String scopeKey}) async {
    final raw = _store.getString('$_metaPrefix$scopeKey');
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    return PrayerMetaModel.fromJson(json.cast<String, dynamic>());
  }

  Future<void> writeMeta({
    required String scopeKey,
    required PrayerMetaModel meta,
  }) async {
    await _rememberScope(scopeKey);
    await _store.setString('$_metaPrefix$scopeKey', jsonEncode(meta.toJson()));
  }

  Future<PrayerRakaatResponseModel?> readRakaat({
    required String cacheKey,
  }) async {
    final raw = _store.getString('$_prayerPrefix$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    return PrayerRakaatResponseModel.fromJson(json.cast<String, dynamic>());
  }

  Future<void> writeRakaat({
    required String scopeKey,
    required String cacheKey,
    required PrayerRakaatResponseModel response,
  }) async {
    await _rememberScope(scopeKey);
    await _store.setString(
      '$_prayerPrefix$cacheKey',
      jsonEncode(response.toJson()),
    );
    final index = _store.getStringList('$_indexPrefix$scopeKey') ?? <String>[];
    if (!index.contains(cacheKey)) {
      await _store.setStringList('$_indexPrefix$scopeKey', [
        ...index,
        cacheKey,
      ]);
    }
  }

  Future<void> clearRakaatsForScope({required String scopeKey}) async {
    final index = _store.getStringList('$_indexPrefix$scopeKey') ?? <String>[];
    for (final cacheKey in index) {
      await _store.remove('$_prayerPrefix$cacheKey');
    }
    await _store.remove('$_indexPrefix$scopeKey');
  }

  Future<void> clearAll() async {
    final scopes = await readScopes();
    for (final scopeKey in scopes) {
      await clearRakaatsForScope(scopeKey: scopeKey);
      await _store.remove('$_metaPrefix$scopeKey');
    }
    final surahKeys = _store.getStringList(_surahIndexKey) ?? const <String>[];
    for (final key in surahKeys) {
      await _store.remove('$_surahPrefix$key');
    }
    await _store.remove(_surahIndexKey);
    await _store.remove(_scopesKey);
  }

  Future<PrayerSurahModel?> readSurah({required String key}) async {
    final raw = _store.getString('$_surahPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    return PrayerSurahModel.fromJson(json.cast<String, dynamic>());
  }

  Future<void> writeSurah({
    required String key,
    required PrayerSurahModel surah,
  }) async {
    await _store.setString('$_surahPrefix$key', jsonEncode(surah.toJson()));
    final index = _store.getStringList(_surahIndexKey) ?? <String>[];
    if (!index.contains(key)) {
      await _store.setStringList(_surahIndexKey, [...index, key]);
    }
  }
}
