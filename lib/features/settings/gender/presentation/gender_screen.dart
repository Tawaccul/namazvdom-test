import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prayday/app/theme/app_radii.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../../app/ui_kit/app_card.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../app/ui_kit/app_list_tile.dart';
import '../../../../app/ui_kit/app_top_bar.dart';
import '../data/gender_repository_memory.dart';
import '../domain/entities/app_gender.dart';
import '../domain/usecases/get_available_genders.dart';
import '../domain/usecases/get_selected_gender.dart';
import '../domain/usecases/set_selected_gender.dart';
import 'gender_controller.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  static const double _blurShowOffset = 100;
  late final GenderController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _showTopBlur = false;

  @override
  void initState() {
    super.initState();
    final repository = GenderRepositoryMemory.instance;
    _controller = GenderController(
      getAvailableGenders: GetAvailableGenders(repository),
      getSelectedGender: GetSelectedGender(repository),
      setSelectedGender: SetSelectedGender(repository),
    );
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _blurShowOffset;
    if (shouldShow == _showTopBlur) return;
    setState(() => _showTopBlur = shouldShow);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 28.h),
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 12.h,
                ),
                children: [
                  AppTopBar(
                    title: context.t('gender.title'),
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(height: 24.h),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return AppCard(
                        radius: AppRadii.pill,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var i = 0;
                              i < _controller.genders.length;
                              i++
                            ) ...[
                              _GenderTile(
                                gender: _controller.genders[i],
                                selected:
                                    _controller.genders[i].id ==
                                    _controller.selected.id,
                                onTap: () =>
                                    _controller.select(_controller.genders[i]),
                              ),
                              if (i != _controller.genders.length - 1)
                                const AppDivider(
                                  insetLeft: 22,
                                  insetRight: 22,
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  final AppGender gender;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: localizedGenderLabel(context, gender.id),
      onTap: onTap,
      trailing: selected
          ? SvgPicture.asset(
              'assets/icons/check.svg',
              width: 14,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
            )
          : SizedBox(width: 16.r, height: 16.r),
    );
  }
}
