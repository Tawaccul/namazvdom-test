import 'package:dio/dio.dart';

import '../../../core/network/api_config.dart';

class SurahApi {
  SurahApi(this._dio, {this.baseUrl = ApiConfig.baseUrl});

  final Dio _dio;
  final String baseUrl;

  Future<Map<String, dynamic>> fetchSurah({
    required String code,
    required String languageCode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/surah',
      queryParameters: {'code': code, 'language': languageCode},
    );
    return response.data ?? const <String, dynamic>{};
  }
}
