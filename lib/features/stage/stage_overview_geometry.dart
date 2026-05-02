import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/stage_step_screen_models.dart';

class StageOverviewGeometry {
  const StageOverviewGeometry({
    required this.pages,
    required this.previewScale,
    required this.pageGap,
    required this.canvasInset,
    required this.fitPadding,
    required this.closingTopInset,
    required this.previewTopShift,
  });

  final List<StagePageReference> pages;
  final double previewScale;
  final double pageGap;
  final double canvasInset;
  final double fitPadding;
  final double closingTopInset;
  final double previewTopShift;

  Size viewportSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Size(size.width, size.height);
  }

  double restingTopInset(BuildContext context) {
    return math.max(MediaQuery.paddingOf(context).top, closingTopInset.h);
  }

  double previewTopInset(BuildContext context) {
    return math.max(
      MediaQuery.paddingOf(context).top,
      restingTopInset(context) - previewTopShift.h,
    );
  }

  double topInsetForScale(BuildContext context, double scale) {
    final normalized = ((scale - previewScale) / (1 - previewScale)).clamp(
      0.0,
      1.0,
    );
    return ui.lerpDouble(
          previewTopInset(context),
          restingTopInset(context),
          normalized,
        ) ??
        restingTopInset(context);
  }

  Size cardSize(BuildContext context) => viewportSize(context);

  int flatIndexForPageReference(int rakaatIndex, int stepIndex) {
    final index = pages.indexWhere(
      (page) => page.rakaatIndex == rakaatIndex && page.stepIndex == stepIndex,
    );
    return index < 0 ? 0 : index;
  }

  Offset cardPosition(BuildContext context, int rakaatIndex, int stepIndex) {
    final size = cardSize(context);
    final flatIndex = flatIndexForPageReference(rakaatIndex, stepIndex);
    final x = canvasInset + flatIndex * (size.width + pageGap);
    return Offset(x, canvasInset);
  }

  Rect contentRect(BuildContext context) {
    final size = cardSize(context);
    final pageCount = math.max(pages.length, 1);
    final width = pageCount * size.width + (pageCount - 1) * pageGap;
    return Rect.fromLTWH(canvasInset, canvasInset, width, size.height);
  }

  Size canvasSize(BuildContext context) {
    final rect = contentRect(context);
    return Size(rect.right + canvasInset, rect.bottom + canvasInset);
  }

  Rect cardRect(BuildContext context, StagePageReference page) {
    final size = cardSize(context);
    final position = cardPosition(context, page.rakaatIndex, page.stepIndex);
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  Matrix4 matrixForPage(
    BuildContext context,
    StagePageReference page, {
    double scale = 1,
  }) {
    final viewport = viewportSize(context);
    final rect = cardRect(context, page);
    final dx =
        (viewport.width - (rect.width * scale)) / 2 - (rect.left * scale);
    final dy = topInsetForScale(context, scale) - (rect.top * scale);
    final matrix = Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
    matrix.setTranslationRaw(dx, dy, 0);
    return matrix;
  }

  Matrix4 clampTransform(BuildContext context, Matrix4 matrix) {
    final rect = contentRect(context);
    final next = Matrix4.copy(matrix);
    final scale = next.storage[0].clamp(previewScale, 1.0).toDouble();
    final viewport = viewportSize(context);

    final minDx = viewport.width - fitPadding - (rect.right * scale);
    final maxDx = fitPadding - (rect.left * scale);
    final rawDx = next.storage[12];
    final clampedDx = rawDx.clamp(minDx, maxDx).toDouble();
    final clampedDy = topInsetForScale(context, scale) - (rect.top * scale);

    next.storage[0] = scale;
    next.storage[5] = scale;
    next.storage[10] = 1;
    next.storage[12] = clampedDx;
    next.storage[13] = clampedDy;
    next.storage[14] = 0;
    return next;
  }

  bool matricesAreEqual(Matrix4 a, Matrix4 b) {
    for (var i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  int nearestFlatIndexFromTransform(BuildContext context, Matrix4 matrix) {
    if (pages.isEmpty) return 0;
    final viewport = viewportSize(context);
    final scale = matrix.storage[0].clamp(previewScale, 1.0).toDouble();
    final dx = matrix.storage[12];
    final viewportCenterX = viewport.width / 2;
    final contentCenterX = (viewportCenterX - dx) / scale;
    final cardWidth = cardSize(context).width;

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < pages.length; i++) {
      final pageCenterX =
          canvasInset + i * (cardWidth + pageGap) + cardWidth / 2;
      final distance = (pageCenterX - contentCenterX).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int flatIndexForViewportPoint(
    BuildContext context,
    Offset viewportPoint,
    Matrix4 matrix,
  ) {
    if (pages.isEmpty) return 0;
    final scale = matrix.storage[0].clamp(previewScale, 1.0).toDouble();
    final dx = matrix.storage[12];
    final dy = matrix.storage[13];
    final contentPoint = Offset(
      (viewportPoint.dx - dx) / scale,
      (viewportPoint.dy - dy) / scale,
    );
    for (var i = 0; i < pages.length; i++) {
      if (cardRect(context, pages[i]).contains(contentPoint)) {
        return i;
      }
    }
    return nearestFlatIndexFromTransform(context, matrix);
  }
}
