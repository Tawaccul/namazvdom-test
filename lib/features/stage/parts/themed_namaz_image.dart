import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Виджет для namaz-картинок, у которых нужно одновременно менять
/// цвет линий и цвет рамки в зависимости от темы.
///
/// SVG в проекте отрисованы в светлой палитре:
///   #6572A4 — линии (силуэт человека и контур рамки),
///   #DCDFE7 — заливка фоновой рамки,
///   #5C6597/#4D5D8E — оттенки линий в seat_*.svg.
///
/// В тёмной теме хотим:
///   линии → #F0F4FF,
///   рамка (фон) → #393945.
class ThemedNamazImage extends StatelessWidget {
  const ThemedNamazImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  static final Map<String, String> _rawCache = {};
  static final Map<String, String> _tintCache = {};

  Future<String> _loadTinted(bool isDark) async {
    final cacheKey = '$assetPath:${isDark ? 'd' : 'l'}';
    final cached = _tintCache[cacheKey];
    if (cached != null) return cached;

    var raw = _rawCache[assetPath];
    raw ??= await rootBundle.loadString(assetPath);
    _rawCache[assetPath] = raw;

    if (!isDark) {
      _tintCache[cacheKey] = raw;
      return raw;
    }

    // Тёмная тема: меняем цвета. Порядок важен — сначала более тёмные
    // оттенки линий, потом основные, потом рамка.
    final tinted = raw
        .replaceAll('#6572A4', '#F0F4FF')
        .replaceAll('#6572a4', '#F0F4FF')
        .replaceAll('#5C6597', '#F0F4FF')
        .replaceAll('#5c6597', '#F0F4FF')
        .replaceAll('#4D5D8E', '#F0F4FF')
        .replaceAll('#4d5d8e', '#F0F4FF')
        .replaceAll('#DCDFE7', '#393945')
        .replaceAll('#dcdfe7', '#393945');

    _tintCache[cacheKey] = tinted;
    return tinted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Синхронный путь: если tinted-SVG уже в кэше, рендерим сразу.
    // Без этого каждый rebuild (например по двойному тапу) проходил бы
    // через пустое состояние FutureBuilder и картинка мигала.
    final cacheKey = '$assetPath:${isDark ? 'd' : 'l'}';
    final cached = _tintCache[cacheKey];
    if (cached != null) {
      return SvgPicture.string(
        cached,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return FutureBuilder<String>(
      future: _loadTinted(isDark),
      builder: (context, snapshot) {
        final svg = snapshot.data;
        if (svg == null) {
          return SizedBox(width: width, height: height);
        }
        return SvgPicture.string(
          svg,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

/// Возвращает true, если для данной картинки нужно применить
/// двухцветный tint (рамка + линии). Для остальных картинок продолжаем
/// использовать стандартный SvgPicture.asset.
bool isThemedNamazImage(String assetPath) {
  const themedBaseNames = {
    'seat',
    'at-tahiyat',
    'stay',
  };
  for (final name in themedBaseNames) {
    if (assetPath.contains('/namaz/images/${name}_male.svg') ||
        assetPath.contains('/namaz/images/${name}_female.svg')) {
      return true;
    }
  }
  return false;
}
