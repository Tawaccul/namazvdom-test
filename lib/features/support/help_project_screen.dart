import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../core/widgets/pressable.dart';

class HelpProjectScreen extends StatefulWidget {
  const HelpProjectScreen({super.key});

  @override
  State<HelpProjectScreen> createState() => _HelpProjectScreenState();
}

class _HelpProjectScreenState extends State<HelpProjectScreen> {
  int _selectedIndex = 0;

  final List<_Plan> _plans = const [
    _Plan(months: 12, discountLabel: '-24%', priceLabel: '1 750 ₽'),
    _Plan(months: 3, discountLabel: '-18%', priceLabel: '490 ₽'),
    _Plan(months: 1, discountLabel: null, priceLabel: '199 ₽'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: Row(
                      children: [
                        _CircleBackButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.t('support.thankYouTitle'),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          context.t('support.description'),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 33.h),
                        for (var i = 0; i < _plans.length; i++) ...[
                          _PlanTile(
                            plan: _plans[i],
                            selected: i == _selectedIndex,
                            onTap: () => setState(() => _selectedIndex = i),
                          ),
                          if (i != _plans.length - 1) SizedBox(height: 14.h),
                        ],
                        SizedBox(height: 33.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _LinkText(
                              label: context.t('support.privacyPolicy'),
                              onTap: () {},
                            ),
                            _LinkText(
                              label: context.t('support.termsOfService'),
                              onTap: () {},
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _SubscribeButton(onTap: () {}),
                        SizedBox(height: 12.h),
                        Text(
                          context.t('support.disclaimer'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                            color: Colors.white.withAlpha(190),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
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

class _Plan {
  const _Plan({
    required this.months,
    required this.discountLabel,
    required this.priceLabel,
  });

  final int months;
  final String? discountLabel;
  final String priceLabel;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Colors.white.withAlpha(52)
        : Colors.white.withValues(alpha: 0.12);
    final border = selected ? Colors.white : null;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
          border: border == null ? null : Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            _CheckBox(selected: selected),
            SizedBox(width: 16.w),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${plan.months} ${'support.months'.plural(plan.months)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.36,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (plan.discountLabel != null) ...[
                    SizedBox(width: 16.w),
                    _DiscountBadge(text: plan.discountLabel!),
                  ],
                ],
              ),
            ),
            Text(
              plan.priceLabel,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.36,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadii.chip.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.white.withAlpha(180);
    return Container(
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 12.r,
              color: const Color(0xFF0A1B4D),
            )
          : null,
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
        ),
        child: Center(
          child: Text(
            context.t('support.subscribe'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF24398B),
              height: 1.2,
            ),
          ),
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

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(26),
              Colors.black.withAlpha(110),
              Colors.black.withAlpha(190),
            ],
            stops: const [0.0, 0.55, 0.78, 1.0],
          ),
        ),
      ),
    );
  }
}
