import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/pressable.dart';

class AboutProjectScreen extends StatelessWidget {
  const AboutProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _CircleBackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Text(
                      context.t('about.title'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(38.r),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 40.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18.r),
                              color: const Color(0xFF1E1E1E),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo-white.png',
                                width: 74.w,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 13.h),
                        Text(
                          context.t(
                            'about.version',
                            namedArgs: {'value': '1.34'},
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 34.h),
                        Text(
                          context.t('about.paragraph1'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          context.t('about.paragraph2'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 54.h),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialPlaceholder(),
                            SizedBox(width: 20),
                            _SocialPlaceholder(),
                            SizedBox(width: 20),
                            _SocialPlaceholder(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

class _SocialPlaceholder extends StatelessWidget {
  const _SocialPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E8),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
