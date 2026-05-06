import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_radii.dart';
import '../models/rakaat_models.dart';
import '../parts/stage_ayah_card.dart';
import '../parts/stage_card.dart';
import '../parts/stage_step_image.dart';

/// Лёгкая копия контента шага для соседних страниц карусели:
/// та же картинка/заголовок/аяты, но без интерактива и без GlobalKey'ев.
class StageGhostStepCard extends StatelessWidget {
  const StageGhostStepCard({
    super.key,
    required this.stepTitle,
    required this.movementDescription,
    required this.cardTextSize,
    required this.softColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.stepImageAsset,
    required this.fallbackStepImageAsset,
    required this.entries,
  });

  final String stepTitle;
  final String movementDescription;
  final double cardTextSize;
  final Color softColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final String stepImageAsset;
  final String fallbackStepImageAsset;
  final List<RakaatStep> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StageCard(
            child: Column(
              children: [
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(AppRadii.inner),
                  ),
                  child: Center(
                    child: StageStepImage(
                      stepImageAsset: stepImageAsset,
                      fallbackStepImageAsset: fallbackStepImageAsset,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      stepTitle,
                      style: TextStyle(
                        fontSize: cardTextSize,
                        height: 1.48,
                        fontWeight: FontWeight.w500,
                        color: textPrimaryColor,
                      ),
                    ),
                    if (movementDescription.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        movementDescription,
                        style: TextStyle(
                          fontSize: cardTextSize,
                          height: 1.48,
                          fontWeight: FontWeight.w500,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++) ...[
            IgnorePointer(
              ignoring: true,
              child: StageAyahCard(
                ayahIndex: i,
                ayah: entries[i],
                textSize: cardTextSize,
                selected: false,
                isPlaying: false,
                progress: 0,
                onTap: () {},
                onPlayPause: () {},
              ),
            ),
            if (i != entries.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
