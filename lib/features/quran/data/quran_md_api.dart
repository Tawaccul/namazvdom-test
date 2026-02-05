import 'package:dio/dio.dart';

import '../model/quran_ayah.dart';

class QuranMdApi {
  QuranMdApi(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://datasets-server.huggingface.co';
  static const int _maxPageSize = 100;

  Future<List<QuranAyah>> fetchSurahAyahs({
    required int surahId,
    required String reciterId,
    int offset = 0,
    int length = _maxPageSize,
  }) async {
    final pageSize = length.clamp(1, _maxPageSize);
    var currentOffset = offset;
    var targetCount = 0;
    final ayahs = <int, QuranAyah>{};

    for (var page = 0; page < 50; page++) {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/rows',
        queryParameters: {
          'dataset': 'Buraaq/quran-md-ayahs',
          'config': 'default',
          'split': 'train',
          'offset': currentOffset,
          'length': pageSize,
        },
      );

      final data = response.data;
      if (data == null) break;

      final rows = (data['rows'] as List?)?.cast<dynamic>() ?? const [];
      if (rows.isEmpty) break;

      for (final item in rows) {
        final row = (item as Map)['row'] as Map<String, dynamic>;
        if ((row['surah_id'] as num).toInt() != surahId) continue;
        if ((row['reciter_id'] as String?) != reciterId) continue;

        targetCount = targetCount == 0
            ? ((row['ayah_count'] as num?)?.toInt() ?? 0)
            : targetCount;

        final ayah = QuranAyah.fromDatasetRow(row);
        if (ayah.audioUrl.isEmpty) continue;
        ayahs[ayah.ayahId] = ayah;
      }

      if (targetCount > 0 && ayahs.length >= targetCount) break;

      currentOffset += pageSize;
    }

    final list = ayahs.values.toList()
      ..sort((a, b) => a.ayahId.compareTo(b.ayahId));
    return list;
  }

  Future<List<QuranAyah>> fetchSurahAyahsWithFallback({
    required int surahId,
    String preferredReciterId = 'alafasy',
  }) async {
    final preferred = await fetchSurahAyahs(
      surahId: surahId,
      reciterId: preferredReciterId,
    );
    if (preferred.isNotEmpty) return preferred;

    // Fallback: pick the first reciter found in the initial window.
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/rows',
      queryParameters: {
        'dataset': 'Buraaq/quran-md-ayahs',
        'config': 'default',
        'split': 'train',
        'offset': 0,
        'length': _maxPageSize,
      },
    );
    final data = response.data;
    if (data == null) return const [];

    final rows = (data['rows'] as List?)?.cast<dynamic>() ?? const [];
    String? fallbackReciter;
    for (final item in rows) {
      final row = (item as Map)['row'] as Map<String, dynamic>;
      if ((row['surah_id'] as num).toInt() != surahId) continue;
      final reciter = row['reciter_id'] as String?;
      if (reciter == null || reciter.isEmpty) continue;
      fallbackReciter = reciter;
      break;
    }
    if (fallbackReciter == null) return const [];
    return fetchSurahAyahs(surahId: surahId, reciterId: fallbackReciter);
  }
}
