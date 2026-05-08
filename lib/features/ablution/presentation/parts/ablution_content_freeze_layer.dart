import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class AblutionContentFreezeLayer extends StatefulWidget {
  const AblutionContentFreezeLayer({
    super.key,
    required this.frozen,
    required this.child,
  });

  final bool frozen;
  final Widget child;

  @override
  State<AblutionContentFreezeLayer> createState() =>
      _AblutionContentFreezeLayerState();
}

class _AblutionContentFreezeLayerState
    extends State<AblutionContentFreezeLayer> {
  final GlobalKey _repaintKey = GlobalKey();
  ui.Image? _frozenImage;
  bool _showing = false;

  @override
  void didUpdateWidget(AblutionContentFreezeLayer old) {
    super.didUpdateWidget(old);
    if (widget.frozen && !old.frozen) {
      // freeze: use the snapshot we already have
      if (_frozenImage != null) {
        setState(() => _showing = true);
      }
    } else if (!widget.frozen && old.frozen) {
      setState(() => _showing = false);
    }
  }

  void _updateSnapshot() {
    if (!mounted || widget.frozen) return;
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
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
    // Capture after every frame while not frozen
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
