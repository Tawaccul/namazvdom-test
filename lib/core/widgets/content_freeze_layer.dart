import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Слой, который замораживает (берёт snapshot) текущего вида ребёнка
/// когда [frozen] становится true. Пока flag не изменился — слой делает
/// snapshot на каждый кадр, чтобы при включении flag сразу показать
/// последнее состояние.
///
/// Используется для overview-режима: пока overview-matrix анимируется
/// к закрытию, под анимацией показывается стабильный snapshot вместо
/// «живого» контента, который мог бы перерисовываться и давать
/// артефакты (двойной рендер, мигания, скачки scroll-позиции).
class ContentFreezeLayer extends StatefulWidget {
  const ContentFreezeLayer({
    super.key,
    required this.frozen,
    required this.child,
  });

  final bool frozen;
  final Widget child;

  @override
  State<ContentFreezeLayer> createState() => _ContentFreezeLayerState();
}

class _ContentFreezeLayerState extends State<ContentFreezeLayer> {
  final GlobalKey _repaintKey = GlobalKey();
  ui.Image? _frozenImage;
  bool _showing = false;

  @override
  void didUpdateWidget(ContentFreezeLayer old) {
    super.didUpdateWidget(old);
    if (widget.frozen && !old.frozen) {
      if (_frozenImage != null) {
        setState(() => _showing = true);
      }
    } else if (!widget.frozen && old.frozen) {
      setState(() => _showing = false);
    }
  }

  void _updateSnapshot() {
    if (!mounted || widget.frozen) return;
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || boundary.debugNeedsPaint) return;
    final pixelRatio = View.of(context).devicePixelRatio;
    final image = boundary.toImageSync(pixelRatio: pixelRatio);
    _frozenImage?.dispose();
    _frozenImage = image;
  }

  @override
  void dispose() {
    _frozenImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.frozen) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _updateSnapshot());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _repaintKey, child: widget.child),
        if (_showing && _frozenImage != null)
          Positioned.fill(
            child: RawImage(
              image: _frozenImage,
              fit: BoxFit.fill,
              scale: View.of(context).devicePixelRatio,
            ),
          ),
      ],
    );
  }
}
