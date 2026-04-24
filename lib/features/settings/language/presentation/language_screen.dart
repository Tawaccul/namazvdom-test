import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prayday/app/theme/app_radii.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_card.dart';
import '../../../../app/ui_kit/app_divider.dart';
import '../../../../app/ui_kit/app_list_tile.dart';
import '../../../../app/ui_kit/app_button.dart';
import '../../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../../app/ui_kit/app_top_bar.dart';
import '../data/language_repository_memory.dart';
import '../domain/entities/app_language.dart';
import '../domain/usecases/get_available_languages.dart';
import '../domain/usecases/get_selected_language.dart';
import '../domain/usecases/set_selected_language.dart';
import 'language_controller.dart';

enum LanguageScreenMode { settings, onboarding }

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({
    super.key,
    this.mode = LanguageScreenMode.settings,
    this.onCompleted,
  });

  final LanguageScreenMode mode;
  final VoidCallback? onCompleted;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const double _blurShowOffset = 100;
  late final LanguageController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _showTopBlur = false;

  @override
  void initState() {
    super.initState();
    final repository = LanguageRepositoryMemory.instance;
    _controller = LanguageController(
      getAvailableLanguages: GetAvailableLanguages(repository),
      getSelectedLanguage: GetSelectedLanguage(repository),
      setSelectedLanguage: SetSelectedLanguage(repository),
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
                    title: context.t('language.title'),
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
                              i < _controller.languages.length;
                              i++
                            ) ...[
                              _LanguageTile(
                                language: _controller.languages[i],
                                selected:
                                    _controller.languages[i].id ==
                                    _controller.selected.id,
                                onTap: () => _onSelect(_controller.languages[i]),
                              ),
                              if (i != _controller.languages.length - 1)
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
                  if (widget.mode == LanguageScreenMode.onboarding) ...[
                    SizedBox(height: 18.h),
                    AppButton.iconRight(
                      label: context.t('common.next'),
                      iconAsset: 'assets/icons/arrow-right.svg',
                      onPressed: widget.onCompleted,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSelect(AppLanguage language) async {
    _controller.select(language);
    await context.setLocale(Locale(language.id));
    if (!mounted) return;
    setState(() {});
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: localizedLanguageLabel(context, language.id),
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
