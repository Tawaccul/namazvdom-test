import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_scope.dart';
import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
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
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeMode = AppScope.themeControllerOf(context).mode;
    final themeLabel = switch (themeMode) {
      ThemeMode.system => context.t('theme.mode.system'),
      ThemeMode.light => context.t('theme.mode.off'),
      ThemeMode.dark => context.t('theme.mode.on'),
    };
    final selectedLanguage = LanguageRepositoryMemory.instance
        .getSelectedLanguage();
    final selectedGender = GenderRepositoryMemory.instance.getSelectedGender();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 28.h),
          children: [
            SizedBox(height: 10.h),
            Row(
              children: [
                _CircleBackButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                SizedBox(width: 12.w),
                Text(
                  context.t('common.back'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
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
            SizedBox(height: 18.h),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: 'assets/icons/theme.svg',
                  title: context.t('menu.theme'),
                  trailingValue: themeLabel,
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
            SizedBox(height: 18.h),
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
                      MaterialPageRoute(builder: (_) => const LanguageScreen()),
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
            SizedBox(height: 18.h),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: 'assets/icons/mail.svg',
                  title: context.t('menu.contactUs'),
                  onTap: () {},
                ),
                _Divider(),
                _MenuRow(
                  icon: 'assets/icons/heart.svg',
                  title: context.t('menu.rateApp'),
                  onTap: () {},
                ),
                _Divider(),
                _MenuRow(
                  icon: 'assets/icons/share.svg',
                  title: context.t('menu.tellFriends'),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 18.h),
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
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = 22.r;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle),
        child: SvgPicture.asset(
          'assets/icons/back.svg',
          width: 7.r,
          height: 15.r,
          fit: BoxFit.none,
          colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
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
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
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
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            SizedBox(width: 6.w),
            SizedBox(width: 32.r, height: 32.r, child: left),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
            SizedBox(width: 10.w),
            SvgPicture.asset(
              'assets/icons/arrow-right-chevron.svg',
              width: 7.r,
              height: 15.h,
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
      height: 32.h,
      width: 32.w,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadii.chip.r),
      ),
      child: SvgPicture.asset(
        icon,
        height: 16.h,
        width: 16.w,
        fit: BoxFit.none,
      ),
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
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
