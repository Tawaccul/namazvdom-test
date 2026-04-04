import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum AppButtonVariant { primary, secondary, tertiary, card, subtitle, dark }

enum AppButtonSize { large, medium }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.leadingIconAsset,
    this.trailingIconAsset,
    this.isLoading = false,
    this.expand = true,
    this.semanticLabel,
  });

  const AppButton.iconLeft({
    super.key,
    required this.label,
    required this.onPressed,
    required String iconAsset,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.expand = true,
    this.semanticLabel,
  }) : leadingIconAsset = iconAsset,
       trailingIconAsset = null;

  const AppButton.iconRight({
    super.key,
    required this.label,
    required this.onPressed,
    required String iconAsset,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.expand = true,
    this.semanticLabel,
  }) : leadingIconAsset = null,
       trailingIconAsset = iconAsset;

  const AppButton.icons({
    super.key,
    required this.label,
    required this.onPressed,
    required String leftIconAsset,
    required String rightIconAsset,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.expand = true,
    this.semanticLabel,
  }) : leadingIconAsset = leftIconAsset,
       trailingIconAsset = rightIconAsset;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  final String? leadingIconAsset;
  final String? trailingIconAsset;

  final bool isLoading;
  final bool expand;
  final String? semanticLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  bool get _interactive => _enabled && !widget.isLoading;

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive && _pressed) {
      _pressed = false;
    }
  }

  void _setPressed(bool value) {
    if (!_interactive) value = false;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsFor(widget.size);
    final colors = context.colors;
    final style = _styleFor(
      widget.variant,
      colors: colors,
      enabled: _enabled,
      pressed: _pressed,
      loading: widget.isLoading,
    );

    final content = _Content(
      label: widget.label,
      style: metrics.textStyle.copyWith(color: style.foreground),
      leadingIconAsset: widget.isLoading ? null : widget.leadingIconAsset,
      trailingIconAsset: widget.isLoading ? null : widget.trailingIconAsset,
      iconColor: style.foreground,
      iconSize: metrics.iconSize,
      gap: metrics.gap,
      isLoading: widget.isLoading,
      spinnerColor: style.foreground,
      spinnerSize: metrics.iconSize,
    );

    final child = AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _interactive && _pressed ? 0.98 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: metrics.height,
        padding: EdgeInsets.symmetric(horizontal: metrics.paddingX),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
          border: style.border == null
              ? null
              : Border.all(color: style.border!, width: 1),
        ),
        child: Center(child: content),
      ),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.semanticLabel ?? widget.label,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _interactive ? (_) => _setPressed(true) : null,
          onTapCancel: _interactive ? () => _setPressed(false) : null,
          onTapUp: _interactive ? (_) => _setPressed(false) : null,
          onTap: _interactive ? widget.onPressed : null,
          child: child,
        ),
      ),
    );
  }
}

class _Metrics {
  const _Metrics({
    required this.height,
    required this.paddingX,
    required this.iconSize,
    required this.gap,
    required this.textStyle,
  });

  final double height;
  final double paddingX;
  final double iconSize;
  final double gap;
  final TextStyle textStyle;
}

_Metrics _metricsFor(AppButtonSize size) {
  switch (size) {
    case AppButtonSize.large:
      return _Metrics(
        height: 58.h,
        paddingX: 20.w,
        iconSize: 22.w,
        gap: 12.w,
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      );
    case AppButtonSize.medium:
      return _Metrics(
        height: 50.h,
        paddingX: 16.w,
        iconSize: 20.w,
        gap: 10.w,
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
      );
  }
}

class _AppButtonStyle {
  const _AppButtonStyle({
    required this.background,
    required this.foreground,
    this.border,
    this.shadow,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final List<BoxShadow>? shadow;
}

_AppButtonStyle _styleFor(
  AppButtonVariant variant, {
  required AppColorPalette colors,
  required bool enabled,
  required bool pressed,
  required bool loading,
}) {
  final effectivePressed = pressed && enabled && !loading;
  switch (variant) {
    case AppButtonVariant.primary:
      if (!enabled) {
        return _AppButtonStyle(
          background: colors.primary.withAlpha(120),
          foreground: Colors.white.withAlpha(179),
        );
      }
      return _AppButtonStyle(
        background: effectivePressed ? colors.secondary : colors.primary,
        foreground: Colors.white,
        shadow: effectivePressed
            ? null
            : [
                BoxShadow(
                  color: colors.primary.withAlpha(64),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
      );

    case AppButtonVariant.secondary:
      if (!enabled) {
        return _AppButtonStyle(
          background: colors.divider,
          foreground: colors.textMuted,
        );
      }
      return _AppButtonStyle(
        background: effectivePressed
            ? Color.lerp(colors.divider, colors.card, 0.14)!
            : colors.divider,
        foreground: colors.textPrimary,
      );

    case AppButtonVariant.tertiary:
      if (!enabled) {
        return _AppButtonStyle(
          background: colors.card,
          foreground: colors.textMuted,
          border: colors.divider,
        );
      }
      return _AppButtonStyle(
        background: effectivePressed ? colors.divider : colors.card,
        foreground: colors.textPrimary,
        border: effectivePressed ? null : colors.divider,
      );

    case AppButtonVariant.card:
      if (!enabled) {
        return _AppButtonStyle(
          background: colors.card,
          foreground: colors.textMuted,
        );
      }
      return _AppButtonStyle(
        background: effectivePressed
            ? Color.lerp(colors.card, colors.divider, 0.2)!
            : colors.card,
        foreground: colors.textPrimary,
      );

    case AppButtonVariant.subtitle:
      if (!enabled) {
        return _AppButtonStyle(
          background: Colors.transparent,
          foreground: colors.textMuted,
        );
      }
      return _AppButtonStyle(
        background: Colors.transparent,
        foreground: effectivePressed
            ? colors.textSecondary
            : colors.textPrimary,
      );

    case AppButtonVariant.dark:
      if (!enabled) {
        return _AppButtonStyle(
          background: colors.darkButton,
          foreground: colors.darkButtonMuted,
        );
      }
      return _AppButtonStyle(
        background: effectivePressed
            ? colors.darkButtonPressed
            : colors.darkButton,
        foreground: Colors.white,
      );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.style,
    required this.leadingIconAsset,
    required this.trailingIconAsset,
    required this.iconColor,
    required this.iconSize,
    required this.gap,
    required this.isLoading,
    required this.spinnerColor,
    required this.spinnerSize,
  });

  final String label;
  final TextStyle style;
  final String? leadingIconAsset;
  final String? trailingIconAsset;
  final Color iconColor;
  final double iconSize;
  final double gap;
  final bool isLoading;
  final Color spinnerColor;
  final double spinnerSize;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: double.infinity,
        child: Center(
          child: SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          ),
        ),
      );
    }

    final leading = leadingIconAsset == null
        ? null
        : _SvgIcon(asset: leadingIconAsset!, size: iconSize, color: iconColor);
    final trailing = trailingIconAsset == null
        ? null
        : _SvgIcon(asset: trailingIconAsset!, size: iconSize, color: iconColor);

    final rowChildren = <Widget>[
      if (leading != null) ...[leading, SizedBox(width: gap)],
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
      if (trailing != null) ...[SizedBox(width: gap), trailing],
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: rowChildren,
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon({
    required this.asset,
    required this.size,
    required this.color,
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
