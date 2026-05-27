import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/ui_kit/app_top_bar.dart';

class AboutProjectScreen extends StatelessWidget {
  const AboutProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 60.h, 14.w, 60.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTopBar(
                title: context.t('about.title'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(38.r),
                ),
                  padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
                        namedArgs: {'value': '1.0.0'},
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

