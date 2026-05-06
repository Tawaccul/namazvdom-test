import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../app/router/app_routes.dart';
import '../onboarding/data/onboarding_repository_memory.dart';

class AppLaunchAnimationView extends StatelessWidget {
  const AppLaunchAnimationView({
    super.key,
    this.controller,
    this.repeat = false,
    this.onLoaded,
  });

  final AnimationController? controller;
  final bool repeat;
  final void Function(LottieComposition)? onLoaded;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        child: Lottie.asset(
          'assets/lottie/anim_glav.json',
          controller: controller,
          fit: BoxFit.contain,
          repeat: repeat,
          addRepaintBoundary: true,
          frameRate: FrameRate.composition,
          renderCache: RenderCache.drawingCommands,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                fit: BoxFit.contain,
              ),
            );
          },
          onLoaded: onLoaded,
        ),
      ),
    );
  }
}

class AppLaunchSplashScreen extends StatefulWidget {
  const AppLaunchSplashScreen({super.key});

  @override
  State<AppLaunchSplashScreen> createState() => _AppLaunchSplashScreenState();
}

class _AppLaunchSplashScreenState extends State<AppLaunchSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  bool _glowStarted = false;
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _glowScale = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutCubic,
    );
    _fallbackTimer = Timer(
      const Duration(milliseconds: 2400),
      _goNextIfNeeded,
    );
    _lottieController.addStatusListener(_handleLottieStatus);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _lottieController.removeStatusListener(_handleLottieStatus);
    _lottieController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleLottieStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _glowStarted) return;
    _startGlow();
  }

  void _startGlow() {
    if (_glowStarted) return;
    _glowStarted = true;
    _fallbackTimer?.cancel();
    _glowController.forward(from: 0).whenComplete(_goNextIfNeeded);
  }

  void _goNextIfNeeded() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(
      OnboardingRepositoryMemory.instance.hasCompletedStart
          ? AppRoutes.home
          : AppRoutes.onboardingStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final circleSize = screenSize.longestSide * 1.45;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _glowScale,
              builder: (context, child) {
                final scale = Tween<double>(
                  begin: 0.0,
                  end: 1.9,
                ).evaluate(_glowScale);
                return Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, -circleSize / 2),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.72,
                    colors: [
                      Color(0x664F7BFF),
                      Color(0x334F7BFF),
                      Color(0x144F7BFF),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.28, 0.58, 1.0],
                  ),
                ),
              ),
            ),
          ),
          AppLaunchAnimationView(
            controller: _lottieController,
            repeat: false,
            onLoaded: (composition) {
              _lottieController
                ..duration = composition.duration
                ..forward(from: 0);
              _fallbackTimer?.cancel();
              _fallbackTimer = Timer(
                composition.duration + const Duration(milliseconds: 700),
                _goNextIfNeeded,
              );
            },
          ),
        ],
      ),
    );
  }
}
