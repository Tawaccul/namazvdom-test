import '../models/prayer_meta_model.dart';
import '../models/prayer_rakaat_response_model.dart';
import '../models/prayer_surah_model.dart';
import '../meta_api.dart';
import '../prayer_api.dart';
import '../surah_api.dart';
import '../../domain/entities/prayer_request_context.dart';

class PrayerRemoteDataSource {
  PrayerRemoteDataSource(this._prayerApi, this._metaApi, this._surahApi);

  final PrayerApi _prayerApi;
  final MetaApi _metaApi;
  final SurahApi _surahApi;

  Future<PrayerRemoteMetaResult> fetchMeta({
    PrayerRequestContext? context,
    String? ifNoneMatch,
  }) async {
    final http = await _metaApi.fetchMeta(
      context: context,
      ifNoneMatch: ifNoneMatch,
    );
    if (http.statusCode == 304) {
      return PrayerRemoteMetaResult.notModified(eTag: http.eTag);
    }

    final metaJson =
        (http.body['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parsed = PrayerMetaModel.fromJson(metaJson);
    final merged = PrayerMetaModel(
      lastModifiedAt: parsed.lastModifiedAt,
      scope: parsed.scope,
      eTag: http.eTag ?? parsed.eTag,
    );
    return PrayerRemoteMetaResult.modified(meta: merged);
  }

  Future<PrayerRakaatResponseModel> fetchRakaat({
    required PrayerRequestContext context,
  }) async {
    final json = await _prayerApi.fetchRakaat(context: context);
    return PrayerRakaatResponseModel.fromJson(json);
  }

  Future<PrayerSurahModel> fetchSurah({
    required String code,
    required String languageCode,
  }) async {
    final json = await _surahApi.fetchSurah(
      code: code,
      languageCode: languageCode,
    );
    return PrayerSurahModel.fromJson(json);
  }
}

class PrayerRemoteMetaResult {
  const PrayerRemoteMetaResult._({
    required this.meta,
    required this.notModified,
    required this.eTag,
  });

  factory PrayerRemoteMetaResult.modified({required PrayerMetaModel meta}) =>
      PrayerRemoteMetaResult._(meta: meta, notModified: false, eTag: meta.eTag);

  factory PrayerRemoteMetaResult.notModified({String? eTag}) =>
      PrayerRemoteMetaResult._(meta: null, notModified: true, eTag: eTag);

  final PrayerMetaModel? meta;
  final bool notModified;
  final String? eTag;
}
