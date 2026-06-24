import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import 'themed_namaz_image.dart';

const Map<String, String> _stepImageBaseNameByCode = {
  'takbir': 'takbir',
  'allahu_akbar': 'takbir',
  'ruku': 'ruku',
  'qiyam': 'stay',
  'standing': 'stay',
  'straightening': 'stay',
  'qawmah': 'stay',
  'istiadha': 'stay',
  'fatiha': 'stay',
  'al_fatiha': 'stay',
  'amin': 'stay',
  'additional_surah': 'stay',
  'sujud': 'sudjud',
  'sajda': 'sudjud',
  'jalsa': 'seat',
  'sitting': 'seat',
  'qaada': 'seat',
  'tashahhud': 'at-tahiyat',
  'at_tahiyat': 'at-tahiyat',
  'at-tahiyat': 'at-tahiyat',
  'taslim_left': 'taslim-left',
  'taslim_right': 'taslim-right',
  'taslim-left': 'taslim-left',
  'taslim-right': 'taslim-right',
};

String resolveStageStepImageAsset({
  required String explicitImageAsset,
  required String stepCode,
  required String title,
  required String movementDescription,
  required String fallbackAsset,
  required String genderCode,
}) {
  final normalizedExplicit = explicitImageAsset.trim();
  if (normalizedExplicit.isNotEmpty) return normalizedExplicit;
  final normalized = stepCode.trim().toLowerCase();
  final baseName =
      _stepImageBaseNameByCode[normalized] ??
      _stepImageBaseNameFromText(title) ??
      _stepImageBaseNameFromText(movementDescription) ??
      _stepImageBaseNameFromText(fallbackAsset) ??
      'stay';
  final normalizedGender = genderCode.trim().toLowerCase() == 'female'
      ? 'female'
      : 'male';
  return 'assets/namaz/images/$baseName'
      '_$normalizedGender.svg';
}

class StageStepImage extends StatelessWidget {
  const StageStepImage({
    super.key,
    required this.stepImageAsset,
    required this.fallbackStepImageAsset,
  });

  final String stepImageAsset;
  final String fallbackStepImageAsset;

  @override
  Widget build(BuildContext context) {

    final width = 244.w;
    if (stepImageAsset.toLowerCase().endsWith('.svg')) {
      if (isThemedNamazImage(stepImageAsset)) {
        return ThemedNamazImage(
          assetPath: stepImageAsset,
          width: width,
          fit: BoxFit.contain,
        );
      }
      return SvgPicture.asset(
        stepImageAsset,
        width: width,
        fit: BoxFit.none,
        theme: SvgTheme(currentColor: context.colors.textPrimary),
        placeholderBuilder: (context) => SizedBox(width: width),
      );
    }
    return Image.asset(
      stepImageAsset,
      width: width,
      fit: BoxFit.none,
      errorBuilder: (context, error, stack) =>
          Image.asset(fallbackStepImageAsset, width: width, fit: BoxFit.none),
    );
  }
}

String? _stepImageBaseNameFromText(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (normalized.contains('taslim-right') ||
      normalized.contains('taslim right') ||
      normalized.contains('поверните голову направо')) {
    return 'taslim-right';
  }
  if (normalized.contains('taslim-left') ||
      normalized.contains('taslim left') ||
      normalized.contains('поверните голову налево')) {
    return 'taslim-left';
  }
  if (normalized.contains('at-tahiyat') ||
      normalized.contains('attahiyat') ||
      normalized.contains('tashahhud') ||
      normalized.contains('тахият') ||
      normalized.contains('ташаххуд')) {
    return 'at-tahiyat';
  }
  if (normalized.contains('takbir') ||
      normalized.contains('такбир') ||
      normalized.contains('аллах велик')) {
    return 'takbir';
  }
  if (normalized.contains('ruku') ||
      normalized.contains('руку') ||
      normalized.contains('поясной поклон')) {
    return 'ruku';
  }
  if (normalized.contains('sujud') ||
      normalized.contains('sudjud') ||
      normalized.contains('sajda') ||
      normalized.contains('суджуд') ||
      normalized.contains('саджда') ||
      normalized.contains('земной поклон')) {
    return 'sudjud';
  }
  if (normalized.contains('sitting') ||
      normalized.contains('jalsa') ||
      normalized.contains('qaada') ||
      normalized.contains('сидя') ||
      normalized.contains('положение сидя')) {
    return 'seat';
  }
  if (normalized.contains('standing') ||
      normalized.contains('qiyam') ||
      normalized.contains('straightening') ||
      normalized.contains('qawmah') ||
      normalized.contains('стоя') ||
      normalized.contains('выпрямление') ||
      normalized.contains('чтение') ||
      normalized.contains('reading') ||
      normalized.contains('мольба о защите')) {
    return 'stay';
  }
  return null;
}
