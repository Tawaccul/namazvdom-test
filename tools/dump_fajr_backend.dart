// Dart-скрипт для дампа всего контента, который возвращает бэкенд для Fajr.
//
// Запуск из корня проекта:
//   dart run tools/dump_fajr_backend.dart
//
// Результат записывается в tools/fajr_backend_dump.json.
//
// Что собирает:
//   1. Все варианты /api/prayer?prayerCode=fajr (gender × script × madhhab)
//   2. /api/prayer/meta
//   3. /api/surah/{code} для всех сур упомянутых в ракаатах
//
// Никаких зависимостей от Flutter — только dart:io.

import 'dart:convert';
import 'dart:io';

const baseUrl = 'https://prayday.io/api';
const prayerCode = 'fajr';

final genders = ['male', 'female'];
final scripts = ['latin', 'cyrillic'];
final madhhabs = ['hanafi', 'shafii', 'maliki', 'hanbali'];
final languages = ['en', 'ru'];

Future<dynamic> _getJson(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.headers.add('Accept', 'application/json');
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  return {
    'status': response.statusCode,
    'url': uri.toString(),
    'body': _safeDecode(body),
  };
}

dynamic _safeDecode(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return body;
  }
}

Future<void> main() async {
  final client = HttpClient();
  final output = <String, dynamic>{};

  // 1. Meta endpoint
  stderr.writeln('Fetching /prayer/meta ...');
  output['meta'] = await _getJson(client, Uri.parse('$baseUrl/prayer/meta'));

  // 2. Prayer rakaats — все комбинации
  final prayerResponses = <Map<String, dynamic>>[];
  final surahCodes = <String>{};

  for (final language in languages) {
    for (final script in scripts) {
      for (final gender in genders) {
        for (final madhhab in madhhabs) {
          final qp = {
            'prayerCode': prayerCode,
            'languageCode': language,
            'script': script,
            'genderCode': gender,
            'madhhabCode': madhhab,
            'rakah': '1',
          };
          final uri = Uri.parse(
            '$baseUrl/prayer',
          ).replace(queryParameters: qp);
          stderr.writeln('  ${uri.queryParameters}');
          final result = await _getJson(client, uri);
          prayerResponses.add({'context': qp, 'response': result});

          // Парсим surah_id из ответа чтобы потом запросить.
          final body = result['body'];
          if (body is Map) {
            _collectSurahCodes(body, surahCodes);
          }
        }
      }
    }
  }
  output['prayerRakaats'] = prayerResponses;

  // 3. Surah endpoints
  stderr.writeln('Found surah codes: $surahCodes');
  final surahResponses = <Map<String, dynamic>>[];
  for (final surahCode in surahCodes) {
    for (final language in languages) {
      for (final script in scripts) {
        final qp = {
          'languageCode': language,
          'script': script,
        };
        final uri = Uri.parse(
          '$baseUrl/surah/$surahCode',
        ).replace(queryParameters: qp);
        stderr.writeln('  $uri');
        final result = await _getJson(client, uri);
        surahResponses.add({
          'surahCode': surahCode,
          'context': qp,
          'response': result,
        });
      }
    }
  }
  output['surahs'] = surahResponses;

  client.close(force: true);

  final outFile = File('tools/fajr_backend_dump.json');
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );
  stderr.writeln('Saved to ${outFile.path}');
}

void _collectSurahCodes(dynamic node, Set<String> out) {
  if (node is Map) {
    final code = node['surahCode'] ?? node['surah_id'] ?? node['surahId'];
    if (code is String && code.isNotEmpty) out.add(code);
    for (final v in node.values) {
      _collectSurahCodes(v, out);
    }
  } else if (node is List) {
    for (final v in node) {
      _collectSurahCodes(v, out);
    }
  }
}
