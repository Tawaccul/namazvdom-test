import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models/stage_step_screen_models.dart';

class StageOverviewGeometry {
  const StageOverviewGeometry({
    required this.pageCount,
    required this.previewScale,
    required this.pageGap,
    required this.canvasInset,
    required this.fitPadding,
    required this.closingTopInset,
    required this.previewTopShift,
  });

  final int pageCount;
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

  Offset cardPositionForFlatIndex(BuildContext context, int flatIndex) {
    final size = cardSize(context);
    final x = canvasInset + flatIndex * (size.width + pageGap);
    return Offset(x, canvasInset);
  }

  Rect contentRect(BuildContext context) {
    final size = cardSize(context);
    final count = math.max(pageCount, 1);
    final width = count * size.width + (count - 1) * pageGap;
    return Rect.fromLTWH(canvasInset, canvasInset, width, size.height);
  }

  Size canvasSize(BuildContext context) {
    final rect = contentRect(context);
    return Size(rect.right + canvasInset, rect.bottom + canvasInset);
  }

  Rect cardRectForFlatIndex(BuildContext context, int flatIndex) {
    final size = cardSize(context);
    final position = cardPositionForFlatIndex(context, flatIndex);
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  Matrix4 matrixForFlatIndex(
    BuildContext context,
    int flatIndex, {
    double scale = 1,
  }) {
    final viewport = viewportSize(context);
    final rect = cardRectForFlatIndex(context, flatIndex);
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
    return false;
  }

  int nearestFlatIndexFromTransform(BuildContext context, Matrix4 matrix) {
    if (pageCount == 0) return 0;
    final viewport = viewportSize(context);
    final scale = matrix.storage[0].clamp(previewScale, 1.0).toDouble();
    final dx = matrix.storage[12];
    final viewportCenterX = viewport.width / 2;
    final contentCenterX = (viewportCenterX - dx) / scale;
    final cardWidth = cardSize(context).width;

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < pageCount; i++) {
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
    if (pageCount == 0) return 0;
    final scale = matrix.storage[0].clamp(previewScale, 1.0).toDouble();
    final dx = matrix.storage[12];
    final dy = matrix.storage[13];
    final contentPoint = Offset(
      (viewportPoint.dx - dx) / scale,
      (viewportPoint.dy - dy) / scale,
    );
    for (var i = 0; i < pageCount; i++) {
      if (cardRectForFlatIndex(context, i).contains(contentPoint)) {
        return i;
      }
    }
    return nearestFlatIndexFromTransform(context, matrix);
  }
}

// Namaz-specific extension that maps rakaat+step to flat index.
extension StageOverviewGeometryForPages on StageOverviewGeometry {
  static StageOverviewGeometry forPages({
    required List<StagePageReference> pages,
    required double previewScale,
    required double pageGap,
    required double canvasInset,
    required double fitPadding,
    required double closingTopInset,
    required double previewTopShift,
  }) => StageOverviewGeometry(
    pageCount: pages.length,
    previewScale: previewScale,
    pageGap: pageGap,
    canvasInset: canvasInset,
    fitPadding: fitPadding,
    closingTopInset: closingTopInset,
    previewTopShift: previewTopShift,
  );

  int flatIndexForPageReference(
    List<StagePageReference> pages,
    int rakaatIndex,
    int stepIndex,
  ) {
    final index = pages.indexWhere(
      (p) => p.rakaatIndex == rakaatIndex && p.stepIndex == stepIndex,
    );
    return index < 0 ? 0 : index;
  }

  Offset cardPosition(
    BuildContext context,
    List<StagePageReference> pages,
    int rakaatIndex,
    int stepIndex,
  ) {
    final flat = flatIndexForPageReference(pages, rakaatIndex, stepIndex);
    return cardPositionForFlatIndex(context, flat);
  }

  Rect cardRect(
    BuildContext context,
    List<StagePageReference> pages,
    StagePageReference page,
  ) {
    final flat = flatIndexForPageReference(
      pages,
      page.rakaatIndex,
      page.stepIndex,
    );
    return cardRectForFlatIndex(context, flat);
  }

  Matrix4 matrixForPage(
    BuildContext context,
    List<StagePageReference> pages,
    StagePageReference page, {
    double scale = 1,
  }) {
    final flat = flatIndexForPageReference(
      pages,
      page.rakaatIndex,
      page.stepIndex,
    );
    return matrixForFlatIndex(context, flat, scale: scale);
  }

  int flatIndexForViewportPointWithPages(
    BuildContext context,
    List<StagePageReference> pages,
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
      if (cardRectForFlatIndex(context, i).contains(contentPoint)) {
        return i;
      }
    }
    return nearestFlatIndexFromTransform(context, matrix);
  }
}
