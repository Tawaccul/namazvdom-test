import 'package:dio/dio.dart';

import '../domain/entities/prayer_request_context.dart';

class MetaApi {
  MetaApi(this._dio, {this.baseUrl = 'http://64.188.60.3'});

  final Dio _dio;
  final String baseUrl;

  Future<PrayerMetaHttpResult> fetchMeta({
    PrayerRequestContext? context,
    String? ifNoneMatch,
  }) async {
    final query = <String, dynamic>{};
    if (context != null) {
      if (context.prayerCode != null) query['prayerCode'] = context.prayerCode;
      if (context.madhhabCode != null) {
        query['madhhabCode'] = context.madhhabCode;
      }
      if (context.genderCode != null) query['genderCode'] = context.genderCode;
      if (context.languageCode != null) {
        query['languageCode'] = context.languageCode;
      }
      if (context.script != null) query['script'] = context.script;
    }

    final headers = <String, dynamic>{};
    if (ifNoneMatch != null && ifNoneMatch.isNotEmpty) {
      headers['if-none-match'] = ifNoneMatch;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/prayer/meta',
      queryParameters: query.isEmpty ? null : query,
      options: Options(
        headers: headers.isEmpty ? null : headers,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    return PrayerMetaHttpResult(
      statusCode: response.statusCode ?? 0,
      body: response.data ?? const <String, dynamic>{},
      eTag: response.headers.value('etag'),
    );
  }
}

class PrayerMetaHttpResult {
  const PrayerMetaHttpResult({
    required this.statusCode,
    required this.body,
    required this.eTag,
  });

  final int statusCode;
  final Map<String, dynamic> body;
  final String? eTag;
}
