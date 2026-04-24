import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/pressable.dart';
import '../models/rakaat_models.dart';

class StageAyahCard extends StatelessWidget {
  const StageAyahCard({
    super.key,
    required this.ayahIndex,
    required this.ayah,
    required this.textSize,
    required this.selected,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
    required this.onPlayPause,
    this.arabicFontSize,
  });

  final int ayahIndex;
  final RakaatStep ayah;
  final double textSize;
  final bool selected;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final double? arabicFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = selected ? colors.primary : Colors.transparent;
    final borderWidth = selected ? 2.0 : 0.0;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadii.card.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withAlpha(26),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AyahPill(
              arabic: ayah.arabic,
              arabicFontSize: arabicFontSize,
              progress: progress,
              isPlaying: isPlaying,
              onPlayPause: onPlayPause,
            ),
            SizedBox(height: 16.h),
            Text(
              ayah.transliteration,
              style: TextStyle(
                fontSize: textSize.sp,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              ayah.translation,
              style: TextStyle(
                fontSize: textSize.sp,
                height: 1.48,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahPill extends StatelessWidget {
  const _AyahPill({
    required this.arabic,
    required this.arabicFontSize,
    required this.progress,
    required this.isPlaying,
    required this.onPlayPause,
  });

  final String arabic;
  final double? arabicFontSize;
  final double progress;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = 58.h;
    final iconAreaWidth = 24.w;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(color: colors.soft)),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final filledWidth =
                    constraints.maxWidth * progress.clamp(0.0, 1.0);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: filledWidth,
                    decoration: BoxDecoration(
                      color: colors.backgroundLightBlue,
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 16.w),
                width: iconAreaWidth,
                height: height,
                child: Pressable(
                  onTap: onPlayPause,
                  borderRadius: BorderRadius.circular(AppRadii.inner.r),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: SvgPicture.asset(
                        isPlaying
                            ? 'assets/icons/pause.svg'
                            : 'assets/icons/play.svg',
                        key: ValueKey(isPlaying),
                        colorFilter: ColorFilter.mode(
                          colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Text(
                    arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    textScaler: TextScaler.noScaling,
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: (arabicFontSize ?? 24).sp,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
