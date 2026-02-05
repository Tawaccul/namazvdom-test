import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../utils/duration_format.dart';

class SeekBar extends StatelessWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.compact = false,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds.clamp(1, 1 << 31);
    final posMs = position.inMilliseconds.clamp(0, maxMs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: compact ? 3.h : 4.h,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: compact ? 6.r : 8.r,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: compact ? 14.r : 18.r,
            ),
          ),
          child: Slider(
            value: posMs.toDouble(),
            min: 0,
            max: maxMs.toDouble(),
            onChanged: (v) => onSeek(Duration(milliseconds: v.round())),
          ),
        ),
        SizedBox(height: compact ? 6.h : 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatMmSs(position),
              style: TextStyle(
                fontSize: (compact ? 12 : 13).sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              formatMmSs(duration),
              style: TextStyle(
                fontSize: (compact ? 12 : 13).sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
