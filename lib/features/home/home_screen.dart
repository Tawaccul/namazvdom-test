import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prayday/app/theme/app_radii.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../core/widgets/pressable.dart';
import '../ablution/presentation/ablution_screen.dart';
import '../menu/menu_screen.dart';
import '../stage/stage_prayer_loader.dart';
import '../stage/stage_step_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _topBlurShowOffset = 60;
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colors.background,
      body: AppBlurredTopOverlay(
        visible: _showTopBlur,
        height: 60,
        maxBlurSigma: 60,
        child: Container(
          decoration: isDark
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF24252E),
                      Color(0xFF1E1F27),
                      Color(0xFF1A1B22),
                    ],
                  ),
                )
              : null,
          child: SafeArea(
            bottom: false,
            top: false,
            child: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14.w, 64.h, 14.w, 28.h), 
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      isDark
                          ? 'assets/images/logo-white.png'
                          : 'assets/images/logo.png',
                      height: 18.5.h,
                    ),
                    SizedBox(width: 12.w),
                    _CircleIconButton(
                      icon: 'assets/icons/more-circle.svg',
                      onTap: () => _openMenu(context),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _HomeMenuCard(
                  title: context.t('home.ablution.title'),
                  subtitle: context.t('home.ablution.subtitle'),
                  trailing: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/icons/ablution-dark.png'
                        : 'assets/icons/ablution-light.png',
                    width: 42.r,
                    height: 42.r,
                  ),
                  onTap: () => _openAblution(context),
                ),
                SizedBox(height: 20.h), 
                _HomeMenuCard(
                  title: context.t('home.prayers.fajr.title'),
                  subtitle: context.t('home.prayers.fajr.subtitle'),
                  trailing: const _Badge.star(count: 2),
                  onTap: () => _openPrayer(
                    context,
                    code: 'fajr',
                    title: localizedPrayerLabel(context, 'fajr'),
                  ),
                ),
                SizedBox(height: 8.h),
                _HomeMenuCard(
                  title: context.t('home.prayers.dhuhr.title'),
                  subtitle: context.t('home.prayers.dhuhr.subtitle'),
                  trailing: const _Badge.star(count: 4),
                  onTap: () => _openPrayer(
                    context,
                    code: 'dhuhr',
                    title: localizedPrayerLabel(context, 'dhuhr'),
                  ),
                ),
                SizedBox(height: 8.h),
                _HomeMenuCard(
                  title: context.t('home.prayers.asr.title'),
                  subtitle: context.t('home.prayers.asr.subtitle'),
                  trailing: const _Badge.star(count: 4),
                  onTap: () => _openPrayer(
                    context,
                    code: 'asr',
                    title: localizedPrayerLabel(context, 'asr'),
                  ),
                ),
                SizedBox(height: 8.h),
                _HomeMenuCard(
                  title: context.t('home.prayers.maghrib.title'),
                  subtitle: context.t('home.prayers.maghrib.subtitle'),
                  trailing: const _Badge.star(count: 3),
                  onTap: () => _openPrayer(
                    context,
                    code: 'maghrib',
                    title: localizedPrayerLabel(context, 'maghrib'),
                  ),
                ),
                SizedBox(height: 8.h),
                _HomeMenuCard(
                  title: context.t('home.prayers.isha.title'),
                  subtitle: context.t('home.prayers.isha.subtitle'),
                  trailing: const _Badge.star(count: 4),
                  onTap: () => _openPrayer(
                    context,
                    code: 'isha',
                    title: localizedPrayerLabel(context, 'isha'),
                  ),
                ),
                SizedBox(height: 20.h),
                _HomeMenuCard(
                  title: context.t('home.additional.title'),
                  subtitle: context.t('home.additional.subtitle'),
                  trailing: const _Badge.dome(count: 3),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPrayer(
    BuildContext context, {
    required String code,
    required String title,
  }) async {
    try {
      final rakaats = await StagePrayerLoader.load(context, prayerCode: code);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StageStepScreen(
            rakaats: rakaats,
            prayerTitle: title,
            prayerCode: code,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = _toPrayerLoadErrorMessage(context, error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _toPrayerLoadErrorMessage(BuildContext context, Object error) {
    final text = error.toString();
    if (text.contains('prayer_not_found') ||
        text.contains('Нет данных для выбранного намаза')) {
      return context.t('errors.prayerNotFound');
    }
    return context.t('errors.failedLoadPrayer');
  }

  void _openMenu(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
  }

  void _openAblution(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AblutionScreen()));
  }
}

class _HomeMenuCard extends StatelessWidget {
  const _HomeMenuCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(AppRadii.inner.r);

    return Pressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        height: 71.h,
        padding: EdgeInsets.only(right: 20.w, left: 20.w),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      height: 1,
                      color: isDark ? colors.textPrimary : colors.secondary,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      color: isDark ? colors.textMuted : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            SizedBox( height: 42.h, child: trailing),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = 21.0;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: colors.card,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: isDark
                ? ColorFilter.mode(colors.textPrimary, BlendMode.srcIn)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge.star({required this.count}) : _type = _BadgeType.star;
  const _Badge.dome({this.count}) : _type = _BadgeType.dome;

  final int? count;
  final _BadgeType _type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stroke = isDark
        ? colors.divider.withAlpha(220)
        : colors.primary.withAlpha(48);
    final textColor = isDark ? colors.textPrimary : colors.textPrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              _type == _BadgeType.star
                  ? 'assets/icons/numeration.svg'
                  : 'assets/icons/additional-prayers.svg',
              width: size,
              height: size,
              color: context.colors.accentColor,
            ),
            if (count != null)
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.2,
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _BadgeType { star, dome }
