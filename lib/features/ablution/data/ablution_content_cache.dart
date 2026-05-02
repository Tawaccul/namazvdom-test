import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/dio_factory.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../../settings/language/data/language_repository_memory.dart';

class AblutionContentCache {
  const AblutionContentCache._();

  static const String _localAssetPath = 'assets/ablution/ablution.json';
  static const String _jsonPrefix = 'ablution_manifest_json';
  static const String _etagPrefix = 'ablution_manifest_etag';

  static Future<void> syncFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKey;
      final etag = prefs.getString('$_etagPrefix:$cacheKey');
      final headers = <String, dynamic>{};
      if (etag != null && etag.isNotEmpty) headers['if-none-match'] = etag;

      final response = await DioFactory.create().get<Map<String, dynamic>>(
        '${ApiConfig.baseUrl}/ablution',
        queryParameters: _queryParameters,
        options: Options(
          headers: headers.isEmpty ? null : headers,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
      if (response.statusCode == 304) return;

      final json = response.data;
      if (json == null) return;
      final manifestJson =
          (json['data'] as Map?)?.cast<String, dynamic>() ?? json;
      final steps = manifestJson['steps'];
      if (steps is! List || steps.isEmpty) return;

      await prefs.setString('$_jsonPrefix:$cacheKey', jsonEncode(manifestJson));
      final remoteEtag = response.headers.value('etag');
      if (remoteEtag != null && remoteEtag.isNotEmpty) {
        await prefs.setString('$_etagPrefix:$cacheKey', remoteEtag);
      }
    } catch (_) {
      // Startup sync must never block the app from showing bundled content.
    }
  }

  static Future<Map<String, dynamic>> loadManifestJson() async {
    final cached = await _readCachedManifestJson();
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_localAssetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> _readCachedManifestJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_jsonPrefix:$_cacheKey');
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final steps = json['steps'];
      if (steps is! List || steps.isEmpty) return null;
      return json;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> get _queryParameters => {
    'languageCode': LanguageRepositoryMemory.instance.getSelectedLanguage().id,
    'genderCode': GenderRepositoryMemory.instance.getSelectedGender().id,
  };

  static String get _cacheKey {
    final languageCode = LanguageRepositoryMemory.instance
        .getSelectedLanguage()
        .id;
    final genderCode = GenderRepositoryMemory.instance.getSelectedGender().id;
    return '$languageCode|$genderCode';
  }
}
