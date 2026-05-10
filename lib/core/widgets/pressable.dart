import 'package:flutter/material.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.triggerOnTapDown = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final bool triggerOnTapDown;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _tapTriggeredOnDown = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.96 : 1,
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: widget.child,
      ),
    );
    if (widget.triggerOnTapDown) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _setPressed(true);
          if (_tapTriggeredOnDown) return;
          _tapTriggeredOnDown = true;
          widget.onTap?.call();
        },
        onPointerCancel: (_) {
          _tapTriggeredOnDown = false;
          _setPressed(false);
        },
        onPointerUp: (_) {
          _tapTriggeredOnDown = false;
          _setPressed(false);
        },
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: child,
    );
  }
}
