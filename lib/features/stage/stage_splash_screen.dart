import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../core/network/dio_factory.dart';
import '../quran/data/quran_md_api.dart';
import 'models/rakaat_models.dart';
import 'stage_step_screen.dart';

class StageSplashScreen extends StatefulWidget {
  const StageSplashScreen({super.key, this.api});

  final QuranMdApi? api;

  @override
  State<StageSplashScreen> createState() => _StageSplashScreenState();
}

class _StageSplashScreenState extends State<StageSplashScreen> {
  late final QuranMdApi _api;

  static List<RakaatData>? _cachedRakaats;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? QuranMdApi(DioFactory.create());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_cachedRakaats != null && _cachedRakaats!.isNotEmpty) {
        _goNext(_cachedRakaats!);
        return;
      }
      final ayahs = await _api.fetchSurahAyahsWithFallback(surahId: 1);
      if (!mounted) return;
      if (ayahs.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No ayahs found.';
        });
        return;
      }
      final audioUrl = ayahs.first.audioUrl;
      final fatihaSteps = ayahs
          .map(
            (a) => RakaatStep(
              arabic: a.ayahAr,
              transliteration: a.ayahTr,
              translation: a.ayahEn,
              audioUrl: a.audioUrl,
            ),
          )
          .toList();
      final rakaats = [
        RakaatData(
          number: 1,
          imageAsset: 'assets/icons/salat-1.png',
          steps: fatihaSteps,
        ),
        RakaatData(
          number: 2,
          imageAsset: 'assets/icons/salat.png',
          steps: [
            const RakaatStep(
              arabic: 'اللّٰهُ أَكْبَرُ',
              transliteration: 'Allahu akbar',
              translation: 'Allah is the Greatest',
              audioUrl: 'assets/audio/takbir.mp3',
            ),
            RakaatStep(
              arabic: 'أﻋُﻮذُ بِاللَّهِ ﻣِﻦَ اﻟﺸَّﻴْﻄَﺎن اﻟﺮَّﺟِﻴﻢ',
              transliteration: 'A\'oothu billaahi minash-shaytanir-rajeem',
              translation: 'I seek Allah\'s protection from the cursed devil',
              audioUrl: 'assets/audio/istiaza.mp3',
            ),
          ],
        ),
      ];
      _cachedRakaats = rakaats;
      _goNext(rakaats);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _goNext(List<RakaatData> rakaats) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => StageStepScreen(rakaats: rakaats),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.card.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 4.h),
                if (_loading) ...[
                  SizedBox(
                    width: 26.r,
                    height: 26.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.r,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Preparing…',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Loading Surah Al-Fatiha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Failed to load',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  FilledButton(
                    onPressed: _load,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill.r),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.card,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
