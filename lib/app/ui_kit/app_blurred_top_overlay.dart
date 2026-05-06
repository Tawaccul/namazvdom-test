import 'package:flutter/material.dart';
import 'package:progressive_blur/progressive_blur.dart';

/// Прогрессивный блюр сверху экрана.
/// Использует пакет progressive_blur (GPU-шейдер) для настоящего
/// градиентного размытия как в iOS.
class AppBlurredTopOverlay extends StatelessWidget {
  const AppBlurredTopOverlay({
    super.key,
    required this.child,
    this.visible = true,
    this.height = 140,
    this.maxBlurSigma = 7,
  });

  final Widget child;
  final bool visible;
  final double height;
  final double maxBlurSigma;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: visible ? 1 : 0),
      builder: (context, t, _) {
        // Определяем где заканчивается зона блюра.
        // Она пропорциональна height относительно полной высоты child.
        // Для простоты считаем, что height задан в логических пикселях
        // и оборачиваем child в Stack, где блюр идёт от верха до height.
        return LayoutBuilder(
          builder: (context, constraints) {
            final blurHeight = height;
            final fullHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            // Доля высоты экрана, которую занимает зона блюра
            final blurEnd = (blurHeight / fullHeight).clamp(0.0, 1.0);
            // Полный блюр в верхних 60% зоны, плавное затухание до конца
            final solidEnd = blurEnd * 0.6;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final tintBase = isDark ? Colors.black : Colors.white;

            return Stack(
              children: [
                ProgressiveBlurWidget(
                  sigma: maxBlurSigma * t,
                  linearGradientBlur: LinearGradientBlur(
                    values: const [1, 0],
                    stops: [solidEnd, blurEnd],
                    start: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  child: child,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: blurHeight,
                  child: IgnorePointer(
                    ignoring: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tintBase.withValues(alpha: 0.01 * t),
                            tintBase.withValues(alpha: 0.0),
                          ],
                          stops: [solidEnd / blurEnd, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
