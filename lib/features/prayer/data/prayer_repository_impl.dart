import 'package:dio/dio.dart';

import '../domain/entities/prayer_meta.dart';
import '../domain/entities/prayer_rakaat.dart';
import '../domain/entities/prayer_request_context.dart';
import '../domain/entities/prayer_surah.dart';
import '../domain/repositories/prayer_repository.dart';
import 'datasources/prayer_cache_data_source.dart';
import 'datasources/prayer_remote_data_source.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  PrayerRepositoryImpl({
    required PrayerRemoteDataSource remote,
    required PrayerCacheDataSource cache,
    this.metaTtl = const Duration(minutes: 10),
  }) : _remote = remote,
       _cache = cache;

  final PrayerRemoteDataSource _remote;
  final PrayerCacheDataSource _cache;
  final Duration metaTtl;

  final Map<String, PrayerMeta> _remoteMetaCacheByScope = {};
  final Map<String, DateTime> _remoteMetaFetchedAtByScope = {};
  final Map<String, Future<void>> _syncFutureByScope = {};
  final Map<String, Future<PrayerRakaat>> _inflightRakaatByKey = {};
  final Map<String, Future<PrayerSurah>> _inflightSurahByKey = {};

  @override
  Future<PrayerMeta> getRemoteMeta({PrayerRequestContext? context}) async {
    final scopeKey = _scopeKeyFor(context);
    await _syncMetaAndInvalidateIfNeeded(context: context);
    final cached = _remoteMetaCacheByScope[scopeKey];
    if (cached != null) return cached;
    final metaModel = await _cache.readMeta(scopeKey: scopeKey);
    if (metaModel != null) return metaModel.toEntity();
    // Fallback: force fetch if nothing cached.
    return _fetchAndCacheRemoteMeta(context: context, forceRefresh: true);
  }

  @override
  Future<PrayerRakaat> getRakaat({
    required PrayerRequestContext context,
  }) async {
    await _syncMetaAndInvalidateIfNeeded(context: context);

    final cached = await _cache.readRakaat(cacheKey: context.cacheKey);
    if (cached != null) return cached.toEntity();

    final inflight = _inflightRakaatByKey[context.cacheKey];
    if (inflight != null) return inflight;

    final future = _fetchAndCacheRakaat(context: context);
    _inflightRakaatByKey[context.cacheKey] = future;
    return future.whenComplete(() {
      _inflightRakaatByKey.remove(context.cacheKey);
    });
  }

  @override
  Future<PrayerSurah> getSurah({
    required String surahCode,
    required String languageCode,
  }) async {
    final key = '${languageCode.trim()}|${surahCode.trim()}';
    final cached = await _cache.readSurah(key: key);
    if (cached != null) return cached.toEntity();

    final inflight = _inflightSurahByKey[key];
    if (inflight != null) return inflight;

    final future = _fetchAndCacheSurah(
      key: key,
      surahCode: surahCode,
      languageCode: languageCode,
    );
    _inflightSurahByKey[key] = future;
    return future.whenComplete(() {
      _inflightSurahByKey.remove(key);
    });
  }

  String _scopeKeyFor(PrayerRequestContext? context) =>
      (context?.scopeKey ?? '').trim();

  Future<PrayerRakaat> _fetchAndCacheRakaat({
    required PrayerRequestContext context,
  }) async {
    try {
      final response = await _remote.fetchRakaat(context: context);
      await _cache.writeRakaat(
        scopeKey: context.scopeKey,
        cacheKey: context.cacheKey,
        response: response,
      );
      return response.toEntity();
    } catch (_) {
      final fallback = await _cache.readRakaat(cacheKey: context.cacheKey);
      if (fallback != null) return fallback.toEntity();
      rethrow;
    }
  }

  Future<PrayerSurah> _fetchAndCacheSurah({
    required String key,
    required String surahCode,
    required String languageCode,
  }) async {
    try {
      final model = await _remote.fetchSurah(
        code: surahCode,
        languageCode: languageCode,
      );
      await _cache.writeSurah(key: key, surah: model);
      return model.toEntity();
    } catch (_) {
      final fallback = await _cache.readSurah(key: key);
      if (fallback != null) return fallback.toEntity();
      rethrow;
    }
  }

  Future<PrayerMeta> _fetchAndCacheRemoteMeta({
    PrayerRequestContext? context,
    required bool forceRefresh,
  }) async {
    var scopeKey = _scopeKeyFor(context);
    var effectiveContext = context;
    final now = DateTime.now();
    final fetchedAt = _remoteMetaFetchedAtByScope[scopeKey];
    final memo = _remoteMetaCacheByScope[scopeKey];

    if (!forceRefresh &&
        memo != null &&
        fetchedAt != null &&
        now.difference(fetchedAt) < metaTtl) {
      return memo;
    }

    PrayerRemoteMetaResult remote;
    try {
      final cachedMetaModel = await _cache.readMeta(scopeKey: scopeKey);
      remote = await _remote.fetchMeta(
        context: effectiveContext,
        ifNoneMatch: cachedMetaModel?.eTag,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 404) rethrow;

      scopeKey = '';
      effectiveContext = null;
      final cachedMetaModel = await _cache.readMeta(scopeKey: scopeKey);
      remote = await _remote.fetchMeta(
        context: effectiveContext,
        ifNoneMatch: cachedMetaModel?.eTag,
      );
    }

    final cachedMetaModel = await _cache.readMeta(scopeKey: scopeKey);

    if (remote.notModified) {
      final cached = cachedMetaModel?.toEntity();
      if (cached != null) {
        _remoteMetaCacheByScope[scopeKey] = cached;
        _remoteMetaFetchedAtByScope[scopeKey] = now;
        return cached;
      }
      // If server says not modified but we have no cache, force fetch.
      return _fetchAndCacheRemoteMeta(context: context, forceRefresh: true);
    }

    final model = remote.meta!;
    final meta = model.toEntity();
    _remoteMetaCacheByScope[scopeKey] = meta;
    _remoteMetaFetchedAtByScope[scopeKey] = now;
    return meta;
  }

  Future<void> _syncMetaAndInvalidateIfNeeded({
    required PrayerRequestContext? context,
  }) {
    final scopeKey = _scopeKeyFor(context);
    final existing = _syncFutureByScope[scopeKey];
    if (existing != null) return existing;
    final future =
        _syncMetaAndInvalidateIfNeededImpl(
          context: context,
          scopeKey: scopeKey,
        ).whenComplete(() {
          _syncFutureByScope.remove(scopeKey);
        });
    _syncFutureByScope[scopeKey] = future;
    return future;
  }

  Future<void> _syncMetaAndInvalidateIfNeededImpl({
    required PrayerRequestContext? context,
    required String scopeKey,
  }) async {
    var effectiveScopeKey = scopeKey;
    PrayerRequestContext? effectiveContext = context;

    // Meta endpoint may not have an entity for a too-specific context.
    PrayerRemoteMetaResult remoteResult;
    try {
      final cachedMetaModel = await _cache.readMeta(
        scopeKey: effectiveScopeKey,
      );
      remoteResult = await _remote.fetchMeta(
        context: effectiveContext,
        ifNoneMatch: cachedMetaModel?.eTag,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 404) rethrow;

      effectiveScopeKey = '';
      effectiveContext = null;
      final cachedMetaModel = await _cache.readMeta(
        scopeKey: effectiveScopeKey,
      );
      remoteResult = await _remote.fetchMeta(
        context: effectiveContext,
        ifNoneMatch: cachedMetaModel?.eTag,
      );
    }

    final cachedMetaModel = await _cache.readMeta(scopeKey: effectiveScopeKey);

    if (remoteResult.notModified) {
      if (cachedMetaModel != null) {
        _remoteMetaCacheByScope[effectiveScopeKey] = cachedMetaModel.toEntity();
        _remoteMetaFetchedAtByScope[effectiveScopeKey] = DateTime.now();
      }
      return;
    }

    final remoteMetaModel = remoteResult.meta!;
    final cached = cachedMetaModel;
    final remoteChanged =
        cached == null ||
        cached.scope != remoteMetaModel.scope ||
        cached.lastModifiedAt != remoteMetaModel.lastModifiedAt ||
        cached.eTag != remoteMetaModel.eTag;

    if (remoteChanged) {
      if (effectiveScopeKey.isEmpty) {
        await _cache.clearAll();
      } else {
        await _cache.clearRakaatsForScope(scopeKey: effectiveScopeKey);
      }
      await _cache.writeMeta(
        scopeKey: effectiveScopeKey,
        meta: remoteMetaModel,
      );
    }

    _remoteMetaCacheByScope[effectiveScopeKey] = remoteMetaModel.toEntity();
    _remoteMetaFetchedAtByScope[effectiveScopeKey] = DateTime.now();
  }
}
