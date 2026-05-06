import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/theme_asset_paths.dart';
import '../../../../core/widgets/pressable.dart';
import '../models/ablution_manifest_models.dart';

Future<int?> showAblutionStepSelectorSheet({
  required BuildContext context,
  required AblutionManifest manifest,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final colors = context.colors;
      return SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 32, 16.w, 10),
          height: MediaQuery.sizeOf(context).height * 0.9,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('ablution.selectSection'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Pressable(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(AppRadii.circle),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: BorderRadius.circular(AppRadii.circle),
                      ),
                      child: SvgPicture.asset(
                        closeIconAssetFor(context),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: manifest.steps.length,
                  separatorBuilder: (context, index) =>
                      Container(height: 1, color: colors.divider),
                  itemBuilder: (context, index) {
                    final step = manifest.steps[index];
                    return Pressable(
                      onTap: () => Navigator.of(context).pop(index),
                      borderRadius: BorderRadius.circular(AppRadii.inner),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 2.w,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.t(step.titleKey),
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.36,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            SvgPicture.asset(
                              'assets/icons/arrow-right-chevron.svg',
                              width: 10,
                              colorFilter: ColorFilter.mode(
                                colors.textMuted,
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.none,
                            ),
                            SizedBox(width: 7.w),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
