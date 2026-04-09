import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prayday/app/theme/app_radii.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/ui_kit/app_button.dart';

class StageOnboardingOverlay extends StatefulWidget {
  const StageOnboardingOverlay({
    super.key,
    required this.stageButtonKey,
    required this.progressCardKey,
    required this.selectedAyahCardKey,
    required this.scrollController,
    required this.onStepChanged,
    required this.onFinish,
  });

  final GlobalKey stageButtonKey;
  final GlobalKey progressCardKey;
  final GlobalKey selectedAyahCardKey;
  final ScrollController scrollController;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onFinish;

  @override
  State<StageOnboardingOverlay> createState() => _StageOnboardingOverlayState();
}

class _StageOnboardingOverlayState extends State<StageOnboardingOverlay> {
  int _stepIndex = 0;
  Rect? _targetRect;
  Rect? _progressRect;
  Rect? _selectedAyahRect;
  bool _contentVisible = false;
  bool _isAdvancingStep = false;
  bool _measureScheduled = false;

  List<_Step> get _steps => const [
    _Step(
      bubbleAlignment: Alignment(-0.82, -0.08),
      notch: _BubbleNotch.topLeft,
      icon: _BubbleIcon.stage,
      highlightStageButton: false,
      highlightProgressCard: true,
      highlightAyahCard: false,
    ),
    _Step(
      bubbleAlignment: Alignment(0.8, -0.57),
      notch: _BubbleNotch.topRight,
      icon: _BubbleIcon.stage,
      highlightStageButton: true,
      highlightProgressCard: false,
      highlightAyahCard: false,
    ),
    _Step(
      bubbleAlignment: Alignment(-0.8, -0.09),
      notch: _BubbleNotch.bottomLeft,
      icon: _BubbleIcon.audio,
      highlightStageButton: false,
      highlightProgressCard: false,
      highlightAyahCard: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
    _scheduleMeasure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _contentVisible = true);
    });
  }

  @override
  void didUpdateWidget(covariant StageOnboardingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
    }
    _scheduleMeasure();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measure();
    });
  }

  void _measure() {
    final stageRect = _measureRectFor(widget.stageButtonKey);
    final progressRect = _measureRectFor(widget.progressCardKey);
    final selectedAyahRect = _measureRectFor(widget.selectedAyahCardKey);
    if (!mounted) return;
    if (_targetRect == stageRect &&
        _progressRect == progressRect &&
        _selectedAyahRect == selectedAyahRect) {
      return;
    }
    setState(() {
      _targetRect = stageRect;
      _progressRect = progressRect;
      _selectedAyahRect = selectedAyahRect;
    });
  }

  Rect? _measureRectFor(GlobalKey key) {
    final ctx = key.currentContext;
    final renderObject = ctx?.findRenderObject();
    final overlayRenderObject = context.findRenderObject();
    if (ctx == null ||
        renderObject is! RenderBox ||
        !renderObject.hasSize ||
        overlayRenderObject is! RenderBox ||
        !overlayRenderObject.hasSize) {
      return null;
    }
    final topLeft = renderObject.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderObject,
    );
    return topLeft & renderObject.size;
  }

  Future<void> _next() async {
    if (_isAdvancingStep) return;
    if (_stepIndex >= _steps.length - 1) {
      widget.onFinish();
      return;
    }

    _isAdvancingStep = true;
    final nextStepIndex = _stepIndex + 1;
    setState(() => _stepIndex = nextStepIndex);
    widget.onStepChanged(nextStepIndex);
    _scheduleMeasure();
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isAdvancingStep = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final localizedMessage = switch (_stepIndex) {
      0 => context.t('stage.onboarding.step1'),
      1 => context.t('stage.onboarding.step2'),
      _ => context.t('stage.onboarding.step3'),
    };
    final holeRects = [
      if (step.highlightStageButton) _targetRect,
      if (step.highlightProgressCard) _progressRect,
      if (step.highlightAyahCard) _selectedAyahRect,
    ].whereType<Rect>().toList(growable: false);

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          CustomPaint(
            painter: _HolePainter(rects: holeRects),
            child: const SizedBox.expand(),
          ),
          AnimatedOpacity(
            opacity: _contentVisible ? 1 : 0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: _contentVisible ? Offset.zero : const Offset(0, -0.02),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      ...previousChildren,
                      ...[currentChild].whereType<Widget>(),
                    ],
                  );
                },
                transitionBuilder: (child, anim) {
                  final fade = CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOut,
                  );
                  final scale = Tween<double>(
                    begin: 0.98,
                    end: 1,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
                child: Align(
                  key: ValueKey(_stepIndex),
                  alignment: step.bubbleAlignment,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _BubbleCard(
                      notch: step.notch,
                      icon: step.icon,
                      message: localizedMessage,
                      onNext: _isAdvancingStep ? null : _next,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.bubbleAlignment,
    required this.notch,
    required this.icon,
    required this.highlightStageButton,
    required this.highlightProgressCard,
    required this.highlightAyahCard,
  });

  final Alignment bubbleAlignment;
  final _BubbleNotch notch;
  final _BubbleIcon icon;
  final bool highlightStageButton;
  final bool highlightProgressCard;
  final bool highlightAyahCard;
}

enum _BubbleNotch { topLeft, topRight, bottomLeft, bottomRight }

enum _BubbleIcon { stage, audio }

class _BubbleCard extends StatelessWidget {
  const _BubbleCard({
    required this.notch,
    required this.icon,
    required this.message,
    required this.onNext,
  });

  final _BubbleNotch notch;
  final _BubbleIcon icon;
  final String message;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: switch (notch) {
            _BubbleNotch.topLeft || _BubbleNotch.topRight => 0,
            _BubbleNotch.bottomLeft || _BubbleNotch.bottomRight => null,
          },
          bottom: switch (notch) {
            _BubbleNotch.bottomLeft || _BubbleNotch.bottomRight => -1.h,
            _BubbleNotch.topLeft || _BubbleNotch.topRight => null,
          },
          left: switch (notch) {
            _BubbleNotch.topLeft || _BubbleNotch.bottomLeft => -9.w,
            _BubbleNotch.topRight || _BubbleNotch.bottomRight => null,
          },
          right: switch (notch) {
            _BubbleNotch.topRight || _BubbleNotch.bottomRight => -9.w,
            _BubbleNotch.topLeft || _BubbleNotch.bottomLeft => null,
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              notch == _BubbleNotch.topRight ||
                      notch == _BubbleNotch.bottomRight
                  ? -1
                  : 1,
              notch == _BubbleNotch.bottomLeft ||
                      notch == _BubbleNotch.bottomRight
                  ? -1
                  : 1,
              1,
            ),
            child: SvgPicture.asset(
              'assets/icons/bubbletail.svg',
              width: 22.r,
              height: 27.r,
              color: colors.card,
              colorFilter: ColorFilter.mode(colors.card, BlendMode.srcIn),
            ),
          ),
        ),
        Container(
          width: 268.w,
          padding: EdgeInsets.all(20.sp),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30.r,
                height: 30.r,
                child: switch (icon) {
                  _BubbleIcon.stage => Center(
                    child: SvgPicture.asset(
                      'assets/icons/slider-horizontal.svg',
                      width: 30.r,
                      height: 30.r,
                      colorFilter: ColorFilter.mode(
                        colors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  _BubbleIcon.audio => Icon(
                    Icons.volume_up_outlined,
                    size: 32.r,
                    color: colors.primary,
                  ),
                },
              ),
              SizedBox(height: 16.h),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 40.h,
                child: AppButton(
                  label: context.t('common.next'),
                  onPressed: onNext,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HolePainter extends CustomPainter {
  const _HolePainter({required this.rects});

  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = const Color(0xC2353948);
    final full = Path()..addRect(Offset.zero & size);

    if (rects.isEmpty) {
      canvas.drawRect(Offset.zero & size, overlayPaint);
      return;
    }

    final holes = Path();
    for (final rect in rects) {
      final radiusValue = (rect.height / 2).clamp(AppRadii.card.r, AppRadii.card.r);
      holes.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radiusValue)),
      );
    }
    final combined = Path.combine(PathOperation.difference, full, holes);

    canvas.drawPath(combined, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    if (oldDelegate.rects.length != rects.length) return true;
    for (var i = 0; i < rects.length; i++) {
      if (oldDelegate.rects[i] != rects[i]) return true;
    }
    return false;
  }
}
