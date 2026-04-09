import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:namazvdom/app/theme/app_radii.dart';

import '../../../../app/l10n/app_localization.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/ui_kit/app_blurred_top_overlay.dart';
import '../../../../app/ui_kit/app_card.dart';
import '../../../../app/ui_kit/app_top_bar.dart';
import '../../../../core/widgets/pressable.dart';
import 'theme_text_size_store.dart';

class TextSizeScreen extends StatefulWidget {
  const TextSizeScreen({super.key});

  @override
  State<TextSizeScreen> createState() => _TextSizeScreenState();
}

class _TextSizeScreenState extends State<TextSizeScreen> {
  static const double _blurShowOffset = 100;
  late final double _initialNormalized;
  late double _currentNormalized;
  final ScrollController _scrollController = ScrollController();
  bool _showTopBlur = false;

  @override
  void initState() {
    super.initState();
    _initialNormalized = ThemeTextSizeStore.normalized;
    _currentNormalized = _initialNormalized;
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  double get _textSize => ThemeTextSizeStore.textSizeFor(_currentNormalized);

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
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      MediaQuery.paddingOf(context).top + 12.h,
                      20.w,
                      30,
                    ),
                    children: [
                      AppTopBar(
                        title: context.t('theme.textSize'),
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      SizedBox(height: 24.h),
                      _DescriptionCard(textSize: _textSize),
                      SizedBox(height: 12.h),
                      _PreviewCard(textSize: _textSize),
                    ],
                  ),
                ),
                _BottomPanel(
                  normalized: _currentNormalized,
                  onChanged: (value) =>
                      setState(() => _currentNormalized = value),
                  onCancel: () {
                    setState(() => _currentNormalized = _initialNormalized);
                    Navigator.of(context).maybePop();
                  },
                  onSave: () {
                    ThemeTextSizeStore.setNormalized(_currentNormalized);
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBlurredTopOverlay(
                horizontalPadding: 20,
                visible: _showTopBlur,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.textSize});

  final double textSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      radius: AppRadii.pill,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('theme.textSizeScreen.takbir'),
            style: TextStyle(
              fontSize: textSize.sp,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            context.t('theme.textSizeScreen.description'),
            style: TextStyle(
              fontSize: textSize.sp,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.textSize});

  final double textSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      radius: AppRadii.pill,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: BorderRadius.circular(AppRadii.inner.r),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اللهُ أَكْبَرُ',
                textAlign: TextAlign.right,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 24.sp,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            context.t('theme.textSizeScreen.previewTransliteration'),
            style: TextStyle(
              fontSize: textSize.sp,
              height: 1.4,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: colors.textPrimary,
            ),
          ),
          Text(
            context.t('theme.textSizeScreen.previewTranslation'),
            style: TextStyle(
              fontSize: textSize.sp,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.normalized,
    required this.onChanged,
    required this.onCancel,
    required this.onSave,
  });

  final double normalized;
  final ValueChanged<double> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: colors.card,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB9B9B9).withValues(alpha: 0.25),
            blurRadius: 24.r,
            offset: Offset(0, -4.h),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.pill.r),
          topRight: Radius.circular(AppRadii.pill.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('theme.textSizeScreen.chooseOptimal'),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'A',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 56.h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        child: _ScaleTrackDecor(
                          color: colors.divider,
                          horizontalInset: 6.r,
                        ),
                      ),
                      IgnorePointer(
                        child: _ScaleMarkersDecor(
                          color: colors.divider,
                          horizontalInset: 6.r,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 8.h,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: colors.primary,
                          tickMarkShape: SliderTickMarkShape.noTickMark,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 12.r,
                            elevation: 0,
                            pressedElevation: 0,
                          ),
                        ),
                        child: Slider(
                          value: normalized,
                          divisions: 2,
                          onChanged: (value) => onChanged(
                            ThemeTextSizeStore.snapNormalized(value),
                          ),
                          min: 0.0,
                          max: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: context.t('common.cancel'),
                  onTap: onCancel,
                  background: colors.soft,
                  textColor: colors.textPrimary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _ActionButton(
                  label: context.t('common.save'),
                  onTap: onSave,
                  background: colors.primary,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.textColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleTrackDecor extends StatelessWidget {
  const _ScaleTrackDecor({required this.color, required this.horizontalInset});

  final Color color;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.pill.r),
            ),
          );
        },
      ),
    );
  }
}

class _ScaleMarkersDecor extends StatelessWidget {
  const _ScaleMarkersDecor({
    required this.color,
    required this.horizontalInset,
  });

  final Color color;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerWidth = 6.w;
          final markerHeight = 24.h;
          final centerLeft = (constraints.maxWidth / 2) - (markerWidth / 2);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: _ScaleMarker(
                  width: markerWidth,
                  height: markerHeight,
                  color: color,
                ),
              ),
              Positioned(
                left: centerLeft,
                child: _ScaleMarker(
                  width: markerWidth,
                  height: markerHeight,
                  color: color,
                ),
              ),
              Positioned(
                right: 0,
                child: _ScaleMarker(
                  width: markerWidth,
                  height: markerHeight,
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScaleMarker extends StatelessWidget {
  const _ScaleMarker({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color),
    );
  }
}
