import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/theme_asset_paths.dart';
import '../../../core/widgets/pressable.dart';
import '../models/stage_step_screen_models.dart';

Future<StageSectionSelection?> showStageSectionSheet({
  required BuildContext context,
  required int rakaatCount,
  required int initialRakaatIndex,
  required List<List<StageStepGroup>> stepGroupsByRakaat,
  required VoidCallback onHaptic,
}) {
  return showModalBottomSheet<StageSectionSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _StageSectionSheet(
        rakaatCount: rakaatCount,
        initialRakaatIndex: initialRakaatIndex,
        stepGroupsByRakaat: stepGroupsByRakaat,
        onHaptic: onHaptic,
      );
    },
  );
}

class _StageSectionSheet extends StatefulWidget {
  const _StageSectionSheet({
    required this.rakaatCount,
    required this.initialRakaatIndex,
    required this.stepGroupsByRakaat,
    required this.onHaptic,
  });

  final int rakaatCount;
  final int initialRakaatIndex;
  final List<List<StageStepGroup>> stepGroupsByRakaat;
  final VoidCallback onHaptic;

  @override
  State<_StageSectionSheet> createState() => _StageSectionSheetState();
}

class _StageSectionSheetState extends State<_StageSectionSheet> {
  late int _selectedRakaat;

  @override
  void initState() {
    super.initState();
    _selectedRakaat = widget.initialRakaatIndex.clamp(
      0,
      widget.rakaatCount - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final steps = widget.stepGroupsByRakaat[_selectedRakaat];

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 10.h),
        height: MediaQuery.sizeOf(context).height * 0.9,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.t('stage.selectSection'),
                    style: TextStyle(
                      fontSize: 20.sp,
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
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      color: colors.soft,
                      borderRadius: BorderRadius.circular(AppRadii.circle),
                    ),
                    child: SvgPicture.asset(
                      closeIconAssetFor(context),
                      width: 24.r,
                      height: 24.r,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: colors.soft,
                borderRadius: BorderRadius.circular(AppRadii.pill.r),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < widget.rakaatCount; i++)
                    Expanded(
                      child: Pressable(
                        onTap: () {
                          widget.onHaptic();
                          setState(() => _selectedRakaat = i);
                        },
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: i == _selectedRakaat
                                ? colors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            context.t(
                              'stage.rakaatLabel',
                              namedArgs: {'count': '${i + 1}'},
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: i == _selectedRakaat
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: steps.length,
                separatorBuilder: (context, index) =>
                    Container(height: 1, color: colors.divider),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Pressable(
                    onTap: () {
                      widget.onHaptic();
                      Navigator.of(
                        context,
                      ).pop(StageSectionSelection(_selectedRakaat, index));
                    },
                    borderRadius: BorderRadius.circular(AppRadii.inner),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20.h,
                        horizontal: 2.w,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                height: 1.36,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          SvgPicture.asset(
                            'assets/icons/arrow-right-chevron.svg',
                            width: 10.r,
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
  }
}
