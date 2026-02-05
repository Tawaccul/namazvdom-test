part of '../stage_step_screen.dart';

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayahIndex,
    required this.ayah,
    required this.selected,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
    required this.onPlayPause,
  });

  final int ayahIndex;
  final RakaatStep ayah;
  final bool selected;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : Colors.black.withOpacity(0.0);
    final borderWidth = selected ? 2.0 : 0.0;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.10),
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
              progress: progress,
              isPlaying: isPlaying,
              onPlayPause: onPlayPause,
            ),
            SizedBox(height: 16.h),
            Text(
              ayah.transliteration,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              ayah.translation,
              style: TextStyle(
                fontSize: 16.sp,
                height: 1.48,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
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
    required this.progress,
    required this.isPlaying,
    required this.onPlayPause,
  });

  final String arabic;
  final double progress;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final height = 60.h;
    final iconAreaWidth = 40.w;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.soft),
              ),
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
                        color: AppColors.primary.withOpacity(0.10),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: iconAreaWidth,
                  height: height,
                  child: Pressable(
                    onTap: onPlayPause,
                    borderRadius: BorderRadius.circular(AppRadii.pill.r),
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
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      arabic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
