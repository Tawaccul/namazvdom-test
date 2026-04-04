import 'package:dio/dio.dart';

import '../domain/entities/prayer_request_context.dart';

class PrayerApi {
  PrayerApi(this._dio, {this.baseUrl = 'http://64.188.60.3'});

  final Dio _dio;
  final String baseUrl;

  Future<Map<String, dynamic>> fetchRakaat({
    required PrayerRequestContext context,
  }) async {
    final query = <String, dynamic>{};
    if (context.prayerCode != null) query['prayerCode'] = context.prayerCode;
    if (context.madhhabCode != null) query['madhhabCode'] = context.madhhabCode;
    if (context.genderCode != null) query['genderCode'] = context.genderCode;
    if (context.languageCode != null) {
      query['languageCode'] = context.languageCode;
    }
    if (context.rakah != null) query['rakah'] = context.rakah;
    if (context.script != null) query['script'] = context.script;

    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/prayer',
      queryParameters: query.isEmpty ? null : query,
    );
    return response.data ?? const <String, dynamic>{};
  }
}
