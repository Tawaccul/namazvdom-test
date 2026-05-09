import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../app/ui_kit/app_top_bar.dart';
import '../../core/widgets/pressable.dart';
import '../settings/gender/data/gender_repository_memory.dart';
import '../settings/gender/presentation/gender_screen.dart';
import '../settings/language/data/language_repository_memory.dart';
import '../settings/language/presentation/language_screen.dart';
import '../settings/theme/presentation/theme_screen.dart';
import '../support/help_project_screen.dart';
import '../about/about_project_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const double _topBlurShowOffset = 100;
  static const String _supportEmail = 'support@prayday.app';
  static const String _androidPackageId = 'com.example.prayday';
  static const String _iosAppId = '0000000000';
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  bool _showTopBlur = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _topBlurShowOffset;
    if (shouldShow == _showTopBlur) return;
    setState(() => _showTopBlur = shouldShow);
  }

  Future<void> _contactUs() async {
    final subject = Uri.encodeComponent('PrayDay support');
    final body = Uri.encodeComponent('');
    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    _showActionUnavailable();
  }

  Future<void> _rateApp() async {
    final uri = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => Uri.parse(
        'https://apps.apple.com/app/id$_iosAppId',
      ),
      _ => Uri.parse(
        'https://play.google.com/store/apps/details?id=$_androidPackageId',
      ),
    };
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    _showActionUnavailable();
  }

  Future<void> _tellFriends() async {
    final text = context.t('menu.shareText') == 'menu.shareText'
        ? 'PrayDay'
        : context.t('menu.shareText');
    await SharePlus.instance.share(ShareParams(text: text));
  }

  void _showActionUnavailable() {
    if (!mounted) return;
    final message =
        context.t('menu.actionUnavailable') == 'menu.actionUnavailable'
        ? 'Action unavailable'
        : context.t('menu.actionUnavailable');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedLanguage = LanguageRepositoryMemory.instance
        .getSelectedLanguage();
    final selectedGender = GenderRepositoryMemory.instance.getSelectedGender();
    void goBack() => Navigator.of(context).maybePop();

    return Scaffold(
      backgroundColor: colors.background,
      body: AppBlurredTopOverlay(
        visible: _showTopBlur,
        height: 60.h,
        maxBlurSigma: 4,
        child: SafeArea(
          bottom: false,
          top: false,
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 52.h, 14.w, 12),
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  CircleBackButton(onTap: goBack),
                  SizedBox(width: 12.w),
                  Pressable(
                    onTap: goBack,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 8.h,
                      ),
                      child: Text(
                        context.t('common.back'),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _MenuCard(
                children: [
                  _MenuRow(
                    icon: 'assets/icons/info.svg',
                    title: context.t('menu.aboutProject'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutProjectScreen(),
                        ),
                      );
                    },
                  ),
                  _Divider(),
                  _MenuRow(
                    icon: 'assets/icons/heart.svg',
                    title: context.t('menu.helpProject'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpProjectScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _MenuCard(
                children: [
                  _MenuRow(
                    icon: 'assets/icons/theme.svg',
                    title: context.t('menu.theme'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ThemeScreen()),
                      );
                      if (!context.mounted) return;
                      setState(() {});
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _MenuCard(
                children: [
                  _MenuRow(
                    icon: 'assets/icons/planet.svg',
                    title: context.t('menu.language'),
                    trailingValue: localizedLanguageLabel(
                      context,
                      selectedLanguage.id,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageScreen(),
                        ),
                      );
                      if (!context.mounted) return;
                      setState(() {});
                    },
                  ),
                  _Divider(),
                  _MenuRow(
                    icon: 'assets/icons/user.svg',
                    title: context.t('menu.yourGender'),
                    trailingValue: localizedGenderLabel(
                      context,
                      selectedGender.id,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GenderScreen()),
                      );
                      if (!context.mounted) return;
                      setState(() {});
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _MenuCard(
                children: [
                  _MenuRow(
                    icon: 'assets/icons/mail.svg',
                    title: context.t('menu.contactUs'),
                    onTap: () => _contactUs(),
                  ),
                  _Divider(),
                  _MenuRow(
                    icon: 'assets/icons/heart.svg',
                    title: context.t('menu.rateApp'),
                    onTap: () => _rateApp(),
                  ),
                  _Divider(),
                  _MenuRow(
                    icon: 'assets/icons/share.svg',
                    title: context.t('menu.tellFriends'),
                    onTap: () => _tellFriends(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _MenuCard(
                children: [
                  _MenuRow(
                    leading: const _ExternalPlaceholder(),
                    title: 'Quranapp.com',
                    onTap: () {},
                  ),
                  _Divider(),
                  _MenuRow(
                    leading: const _ExternalPlaceholder(),
                    title: 'Azkar.ru',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.onTap,
    this.icon,
    this.leading,
    this.trailingValue,
  });

  final String title;
  final VoidCallback onTap;
  final String? icon;
  final Widget? leading;
  final String? trailingValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final left = leading ?? _BlueIcon(icon: icon ?? 'assets/icons/planet.svg');
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(width: 6.w),
            SizedBox(width: 32, height: 32, child: left),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  height: 1.36,
                ),
              ),
            ),
            if (trailingValue != null) ...[
              SizedBox(width: 8.w),
              Text(
                trailingValue!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
            SizedBox(width: 10.w),
            SvgPicture.asset(
              'assets/icons/arrow-right-chevron.svg',
              width: 7,
              height: 15,
              fit: BoxFit.none,
            ),
            SizedBox(width: 10.w),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(left: 54.w, right: 6.w),
      child: Container(height: 1, color: colors.divider),
    );
  }
}

class _BlueIcon extends StatelessWidget {
  const _BlueIcon({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 32,
      width: 32.w,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: SvgPicture.asset(icon, height: 16, width: 16.w, fit: BoxFit.none),
    );
  }
}

class _ExternalPlaceholder extends StatelessWidget {
  const _ExternalPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC5C5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
